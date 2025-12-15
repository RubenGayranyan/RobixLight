package net.robixlab.lightcontrol;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import net.robixlab.lightcontrol.databinding.ActivityMainBinding;
import net.robixlab.lightcontrol.databinding.DialogAddDeviceBinding;
import net.robixlab.lightcontrol.databinding.DialogDeviceActionsBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class MainActivity extends AppCompatActivity
        implements DeviceAdapter.OnDeviceClickListener {

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

        binding.addDeviceFab.setOnClickListener(v ->
                showDeviceDialog(null, -1)
        );

        updateEmptyState();
    }

    private void setupRecycler() {
        deviceAdapter = new DeviceAdapter(devices, this);
        binding.devicesRecycler.setLayoutManager(new LinearLayoutManager(this));
        binding.devicesRecycler.setAdapter(deviceAdapter);
    }

    // ===================== DEVICE ACTIONS =====================

    @Override
    public void onDeviceSelected(Device device, int position) {
        showDeviceActions(device);
    }

    @Override
    public void onDeviceSettingsClicked(Device device, int position) {
        showDeviceDialog(device, position);
    }

    private void showDeviceActions(Device device) {
        DialogDeviceActionsBinding actionsBinding =
                DialogDeviceActionsBinding.inflate(getLayoutInflater());

        AlertDialog dialog = new MaterialAlertDialogBuilder(this)
                .setTitle(device.getName())
                .setView(actionsBinding.getRoot())
                .create();

        actionsBinding.actionTurnRed.setOnClickListener(v -> {
            sendColor(device, 255, 0, 0);
            dialog.dismiss();
        });

        actionsBinding.actionTurnGreen.setOnClickListener(v -> {
            sendColor(device, 0, 255, 0);
            dialog.dismiss();
        });

        actionsBinding.actionTurnBlue.setOnClickListener(v -> {
            sendColor(device, 0, 0, 255);
            dialog.dismiss();
        });

        actionsBinding.actionTurnRainbow.setOnClickListener(v -> {
            sendRainbow(device);
            dialog.dismiss();
        });

        dialog.show();
    }

    public void sendColor(Device device, int r, int g, int b) {
        new Thread(() -> {
            try {
                String urlStr = "http://" + device.getIpAddress()
                        + "/setColor?r=" + r + "&g=" + g + "&b=" + b;

                HttpURLConnection conn =
                        (HttpURLConnection) new URL(urlStr).openConnection();

                conn.setRequestMethod("GET");
                conn.setConnectTimeout(2000);
                conn.setReadTimeout(2000);

                int code = conn.getResponseCode();
                conn.disconnect();

                runOnUiThread(() -> {
                    if (code != 200) {
                        Toast.makeText(this,
                                "Ошибка гаджета",
                                Toast.LENGTH_SHORT).show();
                    }
                });

            } catch (Exception e) {
                runOnUiThread(() ->
                        Toast.makeText(this,
                                "Гаджет недоступен",
                                Toast.LENGTH_SHORT).show()
                );
            }
        }).start();
    }

    private void sendRainbow(Device device) {
        new Thread(() -> {
            try {
                String urlStr = "http://" + device.getIpAddress() + "/rainbow";
                HttpURLConnection conn =
                        (HttpURLConnection) new URL(urlStr).openConnection();

                conn.setRequestMethod("GET");
                conn.setConnectTimeout(2000);
                conn.setReadTimeout(2000);
                conn.getResponseCode();
                conn.disconnect();

            } catch (Exception ignored) {}
        }).start();
    }

    // ===================== ADD / EDIT DEVICE =====================

    private void showDeviceDialog(@Nullable Device deviceToEdit, int position) {
        DialogAddDeviceBinding dialogBinding =
                DialogAddDeviceBinding.inflate(getLayoutInflater());

        if (deviceToEdit != null) {
            dialogBinding.deviceNameInput.setText(deviceToEdit.getName());
            dialogBinding.deviceIpInput.setText(deviceToEdit.getIpAddress());
        }

        AlertDialog dialog = new MaterialAlertDialogBuilder(this)
                .setTitle(deviceToEdit == null
                        ? R.string.add_device
                        : R.string.edit_device)
                .setView(dialogBinding.getRoot())
                .setNegativeButton(R.string.cancel, null)
                .setPositiveButton(R.string.save, null)
                .create();

        dialog.setOnShowListener(d -> {
            Button btn = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
            btn.setOnClickListener(v -> {

                String name = Objects.requireNonNull(dialogBinding.deviceNameInput.getText()).toString().trim();
                String ip = Objects.requireNonNull(dialogBinding.deviceIpInput.getText()).toString().trim();

                if (TextUtils.isEmpty(name) || TextUtils.isEmpty(ip)) {
                    Toast.makeText(this,
                            "Заполните все поля",
                            Toast.LENGTH_SHORT).show();
                    return;
                }

                if (deviceToEdit == null) {
                    devices.add(0, new Device(name, ip, null));
                    deviceAdapter.notifyItemInserted(0);
                } else {
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

    // ===================== STORAGE =====================

    private void loadDevices() {
        SharedPreferences prefs =
                getSharedPreferences(PREFS_NAME, MODE_PRIVATE);

        String json = prefs.getString(KEY_DEVICES, null);
        if (json == null) return;

        try {
            JSONArray arr = new JSONArray(json);
            for (int i = 0; i < arr.length(); i++) {
                JSONObject o = arr.getJSONObject(i);
                devices.add(new Device(
                        o.getString("name"),
                        o.getString("ip"),
                        null
                ));
            }
        } catch (JSONException ignored) {}
    }

    private void saveDevices() {
        JSONArray arr = new JSONArray();
        for (Device d : devices) {
            JSONObject o = new JSONObject();
            try {
                o.put("name", d.getName());
                o.put("ip", d.getIpAddress());
                arr.put(o);
            } catch (JSONException ignored) {}
        }

        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putString(KEY_DEVICES, arr.toString())
                .apply();
    }

    private void updateEmptyState() {
        boolean has = !devices.isEmpty();
        binding.devicesRecycler.setVisibility(has ? View.VISIBLE : View.GONE);
        binding.emptyState.setVisibility(has ? View.GONE : View.VISIBLE);
    }
}
