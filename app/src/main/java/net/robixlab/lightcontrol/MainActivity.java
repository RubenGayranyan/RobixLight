package net.robixlab.lightcontrol;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import net.robixlab.lightcontrol.databinding.ActivityMainBinding;
import net.robixlab.lightcontrol.databinding.DialogAddDeviceBinding;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private DeviceAdapter deviceAdapter;
    private final List<Device> devices = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        setupRecycler();
        binding.addDeviceFab.setOnClickListener(v -> showAddDeviceDialog());
        updateEmptyState();
    }

    private void setupRecycler() {
        deviceAdapter = new DeviceAdapter(devices);
        binding.devicesRecycler.setLayoutManager(new LinearLayoutManager(this));
        binding.devicesRecycler.setAdapter(deviceAdapter);
    }

    private void showAddDeviceDialog() {
        DialogAddDeviceBinding dialogBinding = DialogAddDeviceBinding.inflate(getLayoutInflater());

        AlertDialog dialog = new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.add_device)
                .setView(dialogBinding.getRoot())
                .setNegativeButton(R.string.cancel, null)
                .setPositiveButton(R.string.save, null)
                .create();

        dialog.setOnShowListener(dialogInterface -> {
            Button positiveButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
            positiveButton.setOnClickListener(v -> {
                String name = dialogBinding.deviceNameInput.getText() != null
                        ? dialogBinding.deviceNameInput.getText().toString().trim()
                        : "";
                String ip = dialogBinding.deviceIpInput.getText() != null
                        ? dialogBinding.deviceIpInput.getText().toString().trim()
                        : "";

                dialogBinding.deviceNameLayout.setError(null);
                dialogBinding.deviceIpLayout.setError(null);

                if (TextUtils.isEmpty(name)) {
                    dialogBinding.deviceNameLayout.setError(getString(R.string.error_empty_name));
                    return;
                }

                if (TextUtils.isEmpty(ip)) {
                    dialogBinding.deviceIpLayout.setError(getString(R.string.error_empty_ip));
                    return;
                }

                devices.add(0, new Device(name, ip));
                deviceAdapter.notifyItemInserted(0);
                binding.devicesRecycler.smoothScrollToPosition(0);
                updateEmptyState();
                dialog.dismiss();
            });
        });

        dialog.show();
    }

    private void updateEmptyState() {
        boolean hasDevices = !devices.isEmpty();
        binding.emptyState.setVisibility(hasDevices ? View.GONE : View.VISIBLE);
        binding.devicesRecycler.setVisibility(hasDevices ? View.VISIBLE : View.GONE);
        binding.deviceCounter.setText(String.valueOf(devices.size()));
    }
}
