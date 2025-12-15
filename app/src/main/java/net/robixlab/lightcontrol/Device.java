package net.robixlab.lightcontrol;

public class Device {
    private final String name;
    private final String ipAddress;

    public Device(String name, String ipAddress) {
        this.name = name;
        this.ipAddress = ipAddress;
    }

    public String getName() {
        return name;
    }

    public String getIpAddress() {
        return ipAddress;
    }
}
