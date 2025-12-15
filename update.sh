 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/app/src/main/java/net/robixlab/lightcontrol/Device.java b/app/src/main/java/net/robixlab/lightcontrol/Device.java
index fb8a2fad85cd062359d4173d5eff1f6e35fcd46f..515b531944d1c88266a7fcfbd958afc09991a2d7 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/Device.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/Device.java
@@ -1,19 +1,27 @@
 package net.robixlab.lightcontrol;
 
 public class Device {
-    private final String name;
-    private final String ipAddress;
+    private String name;
+    private String ipAddress;
 
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
+
+    public void setName(String name) {
+        this.name = name;
+    }
+
+    public void setIpAddress(String ipAddress) {
+        this.ipAddress = ipAddress;
+    }
 }
diff --git a/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java b/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
index 0e5926b4128c4e16496ae0da7b37692ea8b44879..98560f15d094f3188e8c708b819616bdd9df3630 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
@@ -1,52 +1,69 @@
 package net.robixlab.lightcontrol;
 
 import android.view.LayoutInflater;
 import android.view.ViewGroup;
 
 import androidx.annotation.NonNull;
 import androidx.recyclerview.widget.RecyclerView;
 
 import net.robixlab.lightcontrol.databinding.ItemDeviceBinding;
 
 import java.util.List;
 
 public class DeviceAdapter extends RecyclerView.Adapter<DeviceAdapter.DeviceViewHolder> {
 
+    public interface OnDeviceClickListener {
+        void onDeviceSelected(Device device, int position);
+    }
+
     private final List<Device> devices;
+    private final OnDeviceClickListener clickListener;
 
-    public DeviceAdapter(List<Device> devices) {
+    public DeviceAdapter(List<Device> devices, OnDeviceClickListener clickListener) {
         this.devices = devices;
+        this.clickListener = clickListener;
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
 
-    static class DeviceViewHolder extends RecyclerView.ViewHolder {
+    class DeviceViewHolder extends RecyclerView.ViewHolder {
         private final ItemDeviceBinding binding;
 
         DeviceViewHolder(@NonNull ItemDeviceBinding binding) {
             super(binding.getRoot());
             this.binding = binding;
         }
 
         void bind(Device device) {
             binding.deviceName.setText(device.getName());
             binding.deviceIp.setText(device.getIpAddress());
+
+            binding.getRoot().setOnClickListener(v -> {
+                if (clickListener == null) {
+                    return;
+                }
+
+                int position = getBindingAdapterPosition();
+                if (position != RecyclerView.NO_POSITION) {
+                    clickListener.onDeviceSelected(device, position);
+                }
+            });
         }
     }
 }
diff --git a/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java b/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
index 6d1a2414ec99c4f4fa9571afdc9fcf29e39a1472..c16eb3ba4332fcaec6002c53ffb46400d63f19f9 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
@@ -1,93 +1,198 @@
 package net.robixlab.lightcontrol;
 
+import android.content.SharedPreferences;
 import android.os.Bundle;
 import android.text.TextUtils;
 import android.view.View;
 import android.widget.Button;
 
+import androidx.annotation.Nullable;
 import androidx.appcompat.app.AlertDialog;
 import androidx.appcompat.app.AppCompatActivity;
 import androidx.recyclerview.widget.LinearLayoutManager;
 
 import com.google.android.material.dialog.MaterialAlertDialogBuilder;
 
 import net.robixlab.lightcontrol.databinding.ActivityMainBinding;
 import net.robixlab.lightcontrol.databinding.DialogAddDeviceBinding;
 
+import org.json.JSONArray;
+import org.json.JSONException;
+import org.json.JSONObject;
+
 import java.util.ArrayList;
 import java.util.List;
 
-public class MainActivity extends AppCompatActivity {
+public class MainActivity extends AppCompatActivity implements DeviceAdapter.OnDeviceClickListener {
+
+    private static final String PREFS_NAME = "devices_prefs";
+    private static final String KEY_DEVICES = "devices";
 
     private ActivityMainBinding binding;
     private DeviceAdapter deviceAdapter;
     private final List<Device> devices = new ArrayList<>();
 
     @Override
     protected void onCreate(Bundle savedInstanceState) {
         super.onCreate(savedInstanceState);
         binding = ActivityMainBinding.inflate(getLayoutInflater());
         setContentView(binding.getRoot());
 
+        loadDevices();
         setupRecycler();
-        binding.addDeviceFab.setOnClickListener(v -> showAddDeviceDialog());
+        binding.addDeviceFab.setOnClickListener(v -> showDeviceDialog(null, -1));
         updateEmptyState();
     }
 
     private void setupRecycler() {
-        deviceAdapter = new DeviceAdapter(devices);
+        deviceAdapter = new DeviceAdapter(devices, this);
         binding.devicesRecycler.setLayoutManager(new LinearLayoutManager(this));
         binding.devicesRecycler.setAdapter(deviceAdapter);
     }
 
-    private void showAddDeviceDialog() {
+    private void showDeviceDialog(@Nullable Device deviceToEdit, int position) {
         DialogAddDeviceBinding dialogBinding = DialogAddDeviceBinding.inflate(getLayoutInflater());
 
+        if (deviceToEdit != null) {
+            dialogBinding.deviceNameInput.setText(deviceToEdit.getName());
+            dialogBinding.deviceIpInput.setText(deviceToEdit.getIpAddress());
+        }
+
         AlertDialog dialog = new MaterialAlertDialogBuilder(this)
-                .setTitle(R.string.add_device)
+                .setTitle(deviceToEdit == null ? R.string.add_device : R.string.edit_device)
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
 
-                devices.add(0, new Device(name, ip));
-                deviceAdapter.notifyItemInserted(0);
-                binding.devicesRecycler.smoothScrollToPosition(0);
+                if (deviceToEdit == null) {
+                    devices.add(0, new Device(name, ip));
+                    deviceAdapter.notifyItemInserted(0);
+                    binding.devicesRecycler.smoothScrollToPosition(0);
+                } else if (position >= 0 && position < devices.size()) {
+                    deviceToEdit.setName(name);
+                    deviceToEdit.setIpAddress(ip);
+                    deviceAdapter.notifyItemChanged(position);
+                }
+
+                saveDevices();
                 updateEmptyState();
                 dialog.dismiss();
             });
         });
 
         dialog.show();
     }
 
+    @Override
+    public void onDeviceSelected(Device device, int position) {
+        showDeviceOptions(device, position);
+    }
+
+    private void showDeviceOptions(Device device, int position) {
+        CharSequence[] options = {
+                getString(R.string.rename_device),
+                getString(R.string.delete_device)
+        };
+
+        new MaterialAlertDialogBuilder(this)
+                .setTitle(device.getName())
+                .setItems(options, (dialog, which) -> {
+                    if (which == 0) {
+                        showDeviceDialog(device, position);
+                    } else if (which == 1) {
+                        confirmDelete(device, position);
+                    }
+                })
+                .show();
+    }
+
+    private void confirmDelete(Device device, int position) {
+        new MaterialAlertDialogBuilder(this)
+                .setTitle(R.string.delete_device)
+                .setMessage(getString(R.string.delete_device_confirmation, device.getName()))
+                .setNegativeButton(R.string.cancel, null)
+                .setPositiveButton(R.string.delete, (dialog, which) -> deleteDevice(position))
+                .show();
+    }
+
+    private void deleteDevice(int position) {
+        if (position < 0 || position >= devices.size()) {
+            return;
+        }
+
+        devices.remove(position);
+        deviceAdapter.notifyItemRemoved(position);
+        saveDevices();
+        updateEmptyState();
+    }
+
+    private void loadDevices() {
+        SharedPreferences preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
+        String devicesJson = preferences.getString(KEY_DEVICES, null);
+        if (devicesJson == null) {
+            return;
+        }
+
+        try {
+            JSONArray array = new JSONArray(devicesJson);
+            for (int i = 0; i < array.length(); i++) {
+                JSONObject item = array.getJSONObject(i);
+                String name = item.optString("name");
+                String ip = item.optString("ip");
+                if (!TextUtils.isEmpty(name) && !TextUtils.isEmpty(ip)) {
+                    devices.add(new Device(name, ip));
+                }
+            }
+        } catch (JSONException e) {
+            e.printStackTrace();
+        }
+    }
+
+    private void saveDevices() {
+        JSONArray array = new JSONArray();
+        for (Device device : devices) {
+            JSONObject item = new JSONObject();
+            try {
+                item.put("name", device.getName());
+                item.put("ip", device.getIpAddress());
+                array.put(item);
+            } catch (JSONException e) {
+                e.printStackTrace();
+            }
+        }
+
+        SharedPreferences preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
+        preferences.edit().putString(KEY_DEVICES, array.toString()).apply();
+    }
+
     private void updateEmptyState() {
         boolean hasDevices = !devices.isEmpty();
         binding.emptyState.setVisibility(hasDevices ? View.GONE : View.VISIBLE);
         binding.devicesRecycler.setVisibility(hasDevices ? View.VISIBLE : View.GONE);
         binding.deviceCounter.setText(String.valueOf(devices.size()));
     }
 }
diff --git a/app/src/main/res/values/strings.xml b/app/src/main/res/values/strings.xml
index b8086a5c40be0f3f240e99f135b6938009ce25e9..d5ad04ed6d2e359e4bb2a33610a62591be7bc6eb 100644
--- a/app/src/main/res/values/strings.xml
+++ b/app/src/main/res/values/strings.xml
@@ -1,27 +1,32 @@
 <resources>
     <string name="app_name">Light Control</string>
     <string name="app_logo">Логотип приложения</string>
     <string name="app_tagline">Управляйте устройствами в несколько кликов</string>
     <string name="add_device">Добавить устройство</string>
     <string name="device_list_title">Мои устройства</string>
     <string name="device_list_empty">Здесь появятся ваши устройства после добавления</string>
     <string name="device_name_hint">Название устройства</string>
     <string name="device_ip_hint">IP адрес устройства</string>
     <string name="error_empty_name">Введите название устройства</string>
     <string name="error_empty_ip">Введите IP адрес</string>
+    <string name="edit_device">Редактировать устройство</string>
+    <string name="rename_device">Переименовать</string>
+    <string name="delete_device">Удалить устройство</string>
+    <string name="delete_device_confirmation">Удалить %1$s?</string>
     <string name="cancel">Отмена</string>
     <string name="save">Сохранить</string>
+    <string name="delete">Удалить</string>
         <!-- Add the missing strings from the error log below -->
         <string name="next">Next</string>
         <string name="previous">Previous</string>
         <string name="action_settings">Settings</string>
         <string name="first_fragment_label">First Fragment</string>
         <string name="second_fragment_label">Second Fragment</string>
         <string name="lorem_ipsum">
             Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent
             libero.
             Sed cursus ante dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis
             sagittis ipsum.
             Praesent mauris. Fusce nec tellus sed augue semper porta. Mauris massa.
         </string>
 </resources>
 
EOF
)