package net.robixlab.lightcontrol;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import net.robixlab.lightcontrol.databinding.ItemDeviceBinding;

import java.util.List;

public class DeviceAdapter extends RecyclerView.Adapter<DeviceAdapter.DeviceViewHolder> {

    public interface OnDeviceClickListener {
        void onDeviceSelected(Device device, int position);
    }

    private final List<Device> devices;
    private final OnDeviceClickListener clickListener;

    public DeviceAdapter(List<Device> devices, OnDeviceClickListener clickListener) {
        this.devices = devices;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public DeviceViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        ItemDeviceBinding binding = ItemDeviceBinding.inflate(
                LayoutInflater.from(parent.getContext()), parent, false);
        return new DeviceViewHolder(binding);
    }

    @Override
    public void onBindViewHolder(@NonNull DeviceViewHolder holder, int position) {
        holder.bind(devices.get(position));
    }

    @Override
    public int getItemCount() {
        return devices.size();
    }

    class DeviceViewHolder extends RecyclerView.ViewHolder {
        private final ItemDeviceBinding binding;

        DeviceViewHolder(@NonNull ItemDeviceBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
        }

        void bind(Device device) {
            binding.deviceName.setText(device.getName());
            Integer port = device.getPort();
            String address = port != null
                    ? device.getIpAddress() + ":" + port
                    : device.getIpAddress();

            binding.deviceIp.setText(address);

            binding.getRoot().setOnClickListener(v -> {
                if (clickListener == null) {
                    return;
                }

                int position = getBindingAdapterPosition();
                if (position != RecyclerView.NO_POSITION) {
                    clickListener.onDeviceSelected(device, position);
                }
            });
        }
    }
}
