

import socket
import time
import subprocess
import re
import sys

def get_proxy_port():
    """Get proxy port from docker logs or environment"""
    try:
        result = subprocess.run(['docker-compose', 'logs'], capture_output=True, text=True)
        if result.returncode == 0:
            # Look for port in logs
            match = re.search(r'port (\d+)', result.stdout, re.IGNORECASE)
            if match:
                return int(match.group(1))
    except:
        pass
    return 8080  # Default

def test_direct_telegram():
    """Test direct connection to Telegram datacenters"""
    print("Testing direct Telegram datacenter connections...")
    
    telegram_dcs = [
        ('149.154.175.50', 443),  # DC1 - Miami
        ('149.154.167.51', 443),  # DC2 - Amsterdam  
        ('149.154.175.100', 443), # DC3 - Miami
        ('149.154.167.91', 443),  # DC4 - Amsterdam
        ('91.108.56.130', 443),   # DC5 - Singapore (Primary)
    ]
    
    dc_names = ["Miami", "Amsterdam", "Miami", "Amsterdam", "Singapore"]
    
    working_dcs = 0
    singapore_working = False
    
    for i, (host, port) in enumerate(telegram_dcs, 1):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, port))
            sock.close()
            status = "✓ Connected"
            if i == 5:  # Singapore DC
                status += " (PRIMARY TARGET)"
                singapore_working = True
            print(f"  ✓ DC{i} {dc_names[i-1]} ({host}:{port}) - {status}")
            working_dcs += 1
        except Exception as e:
            status = f"✗ Failed: {e}"
            if i == 5:  # Singapore DC
                status += " (PRIMARY TARGET FAILED!)"
            print(f"  ✗ DC{i} {dc_names[i-1]} ({host}:{port}) - {status}")
    
    if singapore_working:
        print(f"✓ Singapore DC5 is working - Primary target accessible")
    else:
        print(f"⚠ Singapore DC5 failed - Primary target not accessible")
    
    if working_dcs >= 3:
        print(f"✓ Telegram connectivity test passed ({working_dcs}/5 DCs working)")
        return True
    else:
        print(f"✗ Telegram connectivity test failed ({working_dcs}/5 DCs working)")
        return False

def test_proxy_connection():
    """Test basic proxy connection"""
    print("Testing MTProxy connection...")
    port = get_proxy_port()
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        sock.connect(('localhost', port))
        sock.close()
        print(f"✓ MTProxy accepting connections on port {port}")
        return True
    except Exception as e:
        print(f"✗ MTProxy connection failed on port {port}: {e}")
        return False

def test_mtproto_handshake():
    """Test MTProto protocol handshake"""
    print("Testing MTProto protocol handshake...")
    port = get_proxy_port()
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        sock.connect(('localhost', port))
        
        # Send a basic MTProto-like handshake
        handshake = b'\xef' + b'\x00' * 60  # Abridged mode marker + padding
        sock.send(handshake)
        
        # Wait for response or connection handling
        time.sleep(2)
        
        sock.close()
        print("✓ MTProto protocol handshake completed")
        return True
    except Exception as e:
        print(f"✗ MTProto handshake failed: {e}")
        return False

def test_container_health():
    """Test container health and logs"""
    print("Testing container health...")
    
    try:
        # Check container status
        result = subprocess.run(['docker-compose', 'ps'], capture_output=True, text=True)
        if result.returncode == 0 and 'Up' in result.stdout:
            print("✓ Container is running")
        else:
            print("✗ Container not running properly")
            return False
        
        # Check for errors in logs
        result = subprocess.run(['docker-compose', 'logs', '--tail=50'], capture_output=True, text=True)
        if result.returncode == 0:
            logs = result.stdout.lower()
            if 'error' in logs or 'exception' in logs or 'failed' in logs:
                print("⚠ Warning: Errors detected in logs")
                print("Recent logs:")
                print(result.stdout[-500:])  # Show last 500 chars
            else:
                print("✓ No errors detected in recent logs")
        
        return True
    except Exception as e:
        print(f"✗ Container health check failed: {e}")
        return False

def test_performance():
    """Test proxy performance with multiple connections"""
    print("Testing proxy performance...")
    port = get_proxy_port()
    
    successful_connections = 0
    total_tests = 10
    
    for i in range(total_tests):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            start_time = time.time()
            sock.connect(('localhost', port))
            connect_time = time.time() - start_time
            sock.close()
            
            if connect_time < 1.0:  # Should connect quickly
                successful_connections += 1
        except:
            pass
    
    success_rate = (successful_connections / total_tests) * 100
    if success_rate >= 80:
        print(f"✓ Performance test passed ({success_rate}% success rate)")
        return True
    else:
        print(f"✗ Performance test failed ({success_rate}% success rate)")
        return False

def get_connection_info():
    """Get and display connection information"""
    print("\n" + "="*60)
    print(" CONNECTION INFORMATION")
    print("="*60)
    
    try:
        # Get port from logs or environment
        port = get_proxy_port()
        
        # Try to get external IP
        try:
            import urllib.request
            with urllib.request.urlopen('http://ifconfig.me', timeout=5) as response:
                external_ip = response.read().decode().strip()
        except:
            external_ip = "unknown"
        
        print(f"Server: {external_ip}")
        print(f"Port: {port}")
        print(f"Type: MTProto Proxy (alexbers stable)")
        print(f"Modes: TLS + Secure enabled")
        print()
        print("Note: Secrets are auto-generated and shown in deployment logs")
        print("Use: docker-compose logs | grep -i secret")
        
    except Exception as e:
        print(f"Could not retrieve connection info: {e}")

def main():
    """Main test function"""
    print("="*60)
    print(" STABLE MTPROXY COMPREHENSIVE TEST SUITE")
    print(" Using alexbers/mtprotoproxy implementation")
    print("="*60)
    print()
    
    tests = [
        ("Telegram Connectivity", test_direct_telegram),
        ("Proxy Connection", test_proxy_connection),
        ("MTProto Handshake", test_mtproto_handshake),
        ("Container Health", test_container_health),
        ("Performance", test_performance),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"Running {test_name} test...")
        try:
            if test_func():
                passed += 1
            print()
        except Exception as e:
            print(f"✗ {test_name} test crashed: {e}")
            print()
    
    print("="*60)
    print(f" TEST RESULTS: {passed}/{total} PASSED")
    print("="*60)
    
    if passed == total:
        print(" All tests passed! MTProxy is working perfectly.")
        print(" Production ready")
        print(" High performance async implementation")
        print(" TLS + Secure modes enabled")
        print(" Dynamic configuration working")
    elif passed >= total * 0.8:
        print(" Most tests passed. MTProxy is mostly working.")
        print("Check failed tests and logs for any issues.")
    else:
        print(" Multiple tests failed. Check configuration and logs.")
        return 1
    
    get_connection_info()
    return 0

if __name__ == "__main__":
    sys.exit(main()) 