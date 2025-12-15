package net.robixlab.lightcontrol;

public class Device {
    private String name;
    private String ipAddress;
    private Integer port;

    public Device(String name, String ipAddress, Integer port) {
        this.name = name;
        this.ipAddress = ipAddress;
        this.port = port;
    }

    public String getName() {
        return name;
    }

    public String getIpAddress() {
        return ipAddress;
    }
    public Integer getPort() {
        return port;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }
    public void setPort(Integer port) {
        this.port = port;
    }
}
