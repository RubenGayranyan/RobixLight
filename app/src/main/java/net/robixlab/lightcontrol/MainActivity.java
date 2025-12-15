package net.robixlab.lightcontrol;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import net.robixlab.lightcontrol.databinding.ActivityMainBinding;
import net.robixlab.lightcontrol.databinding.DialogAddDeviceBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity implements DeviceAdapter.OnDeviceClickListener {

    private static final String PREFS_NAME = "devices_prefs";
    private static final String KEY_DEVICES = "devices";

    private ActivityMainBinding binding;
    private DeviceAdapter deviceAdapter;
    private final List<Device> devices = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        loadDevices();
        setupRecycler();
        binding.addDeviceFab.setOnClickListener(v -> showDeviceDialog(null, -1));
        updateEmptyState();
    }

    private void setupRecycler() {
        deviceAdapter = new DeviceAdapter(devices, this);
        binding.devicesRecycler.setLayoutManager(new LinearLayoutManager(this));
        binding.devicesRecycler.setAdapter(deviceAdapter);
    }

    private void showDeviceDialog(@Nullable Device deviceToEdit, int position) {
        DialogAddDeviceBinding dialogBinding = DialogAddDeviceBinding.inflate(getLayoutInflater());

        if (deviceToEdit != null) {
            dialogBinding.deviceNameInput.setText(deviceToEdit.getName());
            dialogBinding.deviceIpInput.setText(deviceToEdit.getIpAddress());
        }

        AlertDialog dialog = new MaterialAlertDialogBuilder(this)
                .setTitle(deviceToEdit == null ? R.string.add_device : R.string.edit_device)
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

                if (deviceToEdit == null) {
                    devices.add(0, new Device(name, ip));
                    deviceAdapter.notifyItemInserted(0);
                    binding.devicesRecycler.smoothScrollToPosition(0);
                } else if (position >= 0 && position < devices.size()) {
                    deviceToEdit.setName(name);
                    deviceToEdit.setIpAddress(ip);
                    deviceAdapter.notifyItemChanged(position);
                }

                saveDevices();
                updateEmptyState();
                dialog.dismiss();
            });
        });

        dialog.show();
    }

    @Override
    public void onDeviceSelected(Device device, int position) {
        showDeviceOptions(device, position);
    }

    private void showDeviceOptions(Device device, int position) {
        CharSequence[] options = {
                getString(R.string.rename_device),
                getString(R.string.delete_device)
        };

        new MaterialAlertDialogBuilder(this)
                .setTitle(device.getName())
                .setItems(options, (dialog, which) -> {
                    if (which == 0) {
                        showDeviceDialog(device, position);
                    } else if (which == 1) {
                        confirmDelete(device, position);
                    }
                })
                .show();
    }

    private void confirmDelete(Device device, int position) {
        new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.delete_device)
                .setMessage(getString(R.string.delete_device_confirmation, device.getName()))
                .setNegativeButton(R.string.cancel, null)
                .setPositiveButton(R.string.delete, (dialog, which) -> deleteDevice(position))
                .show();
    }

    private void deleteDevice(int position) {
        if (position < 0 || position >= devices.size()) {
            return;
        }

        devices.remove(position);
        deviceAdapter.notifyItemRemoved(position);
        saveDevices();
        updateEmptyState();
    }

    private void loadDevices() {
        SharedPreferences preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String devicesJson = preferences.getString(KEY_DEVICES, null);
        if (devicesJson == null) {
            return;
        }

        try {
            JSONArray array = new JSONArray(devicesJson);
            for (int i = 0; i < array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                String name = item.optString("name");
                String ip = item.optString("ip");
                if (!TextUtils.isEmpty(name) && !TextUtils.isEmpty(ip)) {
                    devices.add(new Device(name, ip));
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void saveDevices() {
        JSONArray array = new JSONArray();
        for (Device device : devices) {
            JSONObject item = new JSONObject();
            try {
                item.put("name", device.getName());
                item.put("ip", device.getIpAddress());
                array.put(item);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        SharedPreferences preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        preferences.edit().putString(KEY_DEVICES, array.toString()).apply();
    }

    private void updateEmptyState() {
        boolean hasDevices = !devices.isEmpty();
        binding.emptyState.setVisibility(hasDevices ? View.GONE : View.VISIBLE);
        binding.devicesRecycler.setVisibility(hasDevices ? View.VISIBLE : View.GONE);
        binding.deviceCounter.setText(String.valueOf(devices.size()));
    }
}
