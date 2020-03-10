import sys
import paramiko
import time
import subprocess
import select

PID = None
PROC = None


def launch_qemu_vm():
    global PROC
    command = "bash launch.sh"
    PROC = subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def terminate_qemu_vm():
    global PROC
    PROC.kill()


def mac_enable_ssh_on_image():
    command = "hdiutil mount 2020-02-13-raspbian-buster-lite.img -mountpoint /Volumes/boot"
    subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    time.sleep(3.0)

    command = "echo 'HelloWorld!' > /Volumes/boot/ssh"
    subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    time.sleep(3.0)

    command = "hdiutil unmount /Volumes/boot"
    subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    return True


def remove_past_vm_fingerprint():
    command = """ssh-keygen -R '[127.0.0.1]:2222'"""
    subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    return True

    
def execute_with_ssh(command, hostname, port, username, password):

    result = False
    client = paramiko.SSHClient()
    try:
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.WarningPolicy)
    
        client.connect(hostname, port=port, username=username, password=password, timeout=1.0, banner_timeout=1.0, look_for_keys=False)

        stdin, stdout, stderr = client.exec_command(command)

        # Wait for the command to terminate
        while not stdout.channel.exit_status_ready():
            # Only print data if there is data to read in the channel
            if stdout.channel.recv_ready():
                rl, wl, xl = select.select([stdout.channel], [], [], 0.0)
                if len(rl) > 0:
                    # Print data from stdout
                    bytes = stdout.channel.recv(1024)
                    line = bytes.decode('utf-8')
                    print(line, end="")

        result = True
    except:
        print("Cannot connect: I will try again in 5 seconds")
        time.sleep(5.0)
    finally:
        client.close()
    
    return result


def upload_file(source, destination, hostname, port, username, password):

    result = False
    client = paramiko.SSHClient()
    try:
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.WarningPolicy)
    
        client.connect(hostname, port=port, username=username, password=password, look_for_keys=False)

        sftp = client.open_sftp()
        sftp.put(source, destination)
        sftp.close()
        
        result = True
    except:
        print("Cannot connect: I will try again in 5 seconds")
        time.sleep(5.0)
    finally:
        client.close()
    
    return result


def mac_create_network_bridge(bridge_name):
    command = """
    sudo ifconfig en0 down ####Shut Down the interface #####
sudo ifconfig en0 inet delete ####To clean out the old sys hooks. Don't worry you did uninstall the driver ##### Then:

sudo ifconfig bridge0 create
$ sudo ifconfig bridge0 addm en0 addm tap0
$ sudo ifconfig bridge0 up
"""
    PROC = subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    return True


def mac_destroy_network_bridge(bridge_name):
    command = """
    sudo ifconfig en0 down ####Shut Down the interface #####
sudo ifconfig en0 inet delete ####To clean out the old sys hooks. Don't worry you did uninstall the driver ##### Then:

sudo ifconfig bridge0 create
$ sudo ifconfig bridge0 addm en0 addm tap0
$ sudo ifconfig bridge0 up
"""
    PROC = subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    return True


def customize_image():

    loop = False
    while not loop:
        print("I check that the VM is available")
        loop = execute_with_ssh("uname -a", "127.0.0.1", 2222, "pi", "raspberry")
        time.sleep(5.0)

    loop = False
    while not loop:
        print("Uploading 'install.sh' script")
        loop1 = upload_file("templates/install.sh", "/tmp/install.sh", "127.0.0.1", 2222, "pi", "raspberry")
        print("Uploading 'prepare.sh' script")
        loop2 = upload_file("templates/prepare.sh", "/tmp/prepare.sh", "127.0.0.1", 2222, "pi", "raspberry")
        loop = loop1 and loop2
        time.sleep(5.0)

    loop = False
    while not loop:
        print("Prepare C9 installation")
        loop = execute_with_ssh("sudo bash /tmp/prepare.sh", "127.0.0.1", 2222, "pi", "raspberry")
        time.sleep(5.0)

    loop = False
    while not loop:
        print("Install C9")
        loop = execute_with_ssh("sudo bash /tmp/install.sh", "127.0.0.1", 2222, "pi", "raspberry")
        time.sleep(5.0)


if __name__ == "__main__":
    remove_past_vm_fingerprint()
    mac_enable_ssh_on_image()
    launch_qemu_vm()
    customize_image()
    terminate_qemu_vm()
    
    sys.exit(0)

