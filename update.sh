 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/app/src/main/java/net/robixlab/lightcontrol/Device.java b/app/src/main/java/net/robixlab/lightcontrol/Device.java
index 515b531944d1c88266a7fcfbd958afc09991a2d7..0913d64c09c2ca8323fd0d07141934ff692271ee 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/Device.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/Device.java
@@ -1,27 +1,42 @@
 package net.robixlab.lightcontrol;
 
 public class Device {
     private String name;
     private String ipAddress;
+    private Integer port;
 
     public Device(String name, String ipAddress) {
         this.name = name;
         this.ipAddress = ipAddress;
     }
 
+    public Device(String name, String ipAddress, Integer port) {
+        this.name = name;
+        this.ipAddress = ipAddress;
+        this.port = port;
+    }
+
     public String getName() {
         return name;
     }
 
     public String getIpAddress() {
         return ipAddress;
     }
 
+    public Integer getPort() {
+        return port;
+    }
+
     public void setName(String name) {
         this.name = name;
     }
 
     public void setIpAddress(String ipAddress) {
         this.ipAddress = ipAddress;
     }
+
+    public void setPort(Integer port) {
+        this.port = port;
+    }
 }
diff --git a/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java b/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
index 98560f15d094f3188e8c708b819616bdd9df3630..72354c34c6c02dcc7bc6c2c42c399461afc104a7 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/DeviceAdapter.java
@@ -30,40 +30,45 @@ public class DeviceAdapter extends RecyclerView.Adapter<DeviceAdapter.DeviceView
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
-            binding.deviceIp.setText(device.getIpAddress());
+            Integer port = device.getPort();
+            String address = port != null
+                    ? device.getIpAddress() + ":" + port
+                    : device.getIpAddress();
+
+            binding.deviceIp.setText(address);
 
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
diff --git a/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java b/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
index c16eb3ba4332fcaec6002c53ffb46400d63f19f9..e65ca008fde853021eab83dbfb4f77960b530cf2 100644
--- a/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
+++ b/app/src/main/java/net/robixlab/lightcontrol/MainActivity.java
@@ -34,89 +34,113 @@ public class MainActivity extends AppCompatActivity implements DeviceAdapter.OnD
 
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
+            Integer port = deviceToEdit.getPort();
+            if (port != null) {
+                dialogBinding.devicePortInput.setText(String.valueOf(port));
+            }
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
+                String portText = dialogBinding.devicePortInput.getText() != null
+                        ? dialogBinding.devicePortInput.getText().toString().trim()
+                        : "";
 
                 dialogBinding.deviceNameLayout.setError(null);
                 dialogBinding.deviceIpLayout.setError(null);
+                dialogBinding.devicePortLayout.setError(null);
 
                 if (TextUtils.isEmpty(name)) {
                     dialogBinding.deviceNameLayout.setError(getString(R.string.error_empty_name));
                     return;
                 }
 
                 if (TextUtils.isEmpty(ip)) {
                     dialogBinding.deviceIpLayout.setError(getString(R.string.error_empty_ip));
                     return;
                 }
 
+                Integer port = null;
+                if (!TextUtils.isEmpty(portText)) {
+                    try {
+                        int parsedPort = Integer.parseInt(portText);
+                        if (parsedPort <= 0 || parsedPort > 65535) {
+                            dialogBinding.devicePortLayout.setError(getString(R.string.error_invalid_port));
+                            return;
+                        }
+                        port = parsedPort;
+                    } catch (NumberFormatException e) {
+                        dialogBinding.devicePortLayout.setError(getString(R.string.error_invalid_port));
+                        return;
+                    }
+                }
+
                 if (deviceToEdit == null) {
-                    devices.add(0, new Device(name, ip));
+                    devices.add(0, new Device(name, ip, port));
                     deviceAdapter.notifyItemInserted(0);
                     binding.devicesRecycler.smoothScrollToPosition(0);
                 } else if (position >= 0 && position < devices.size()) {
                     deviceToEdit.setName(name);
                     deviceToEdit.setIpAddress(ip);
+                    deviceToEdit.setPort(port);
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
@@ -141,58 +165,67 @@ public class MainActivity extends AppCompatActivity implements DeviceAdapter.OnD
 
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
+                Integer port = null;
+                if (item.has("port") && !item.isNull("port")) {
+                    int parsedPort = item.optInt("port", -1);
+                    if (parsedPort > 0) {
+                        port = parsedPort;
+                    }
+                }
+
                 if (!TextUtils.isEmpty(name) && !TextUtils.isEmpty(ip)) {
-                    devices.add(new Device(name, ip));
+                    devices.add(new Device(name, ip, port));
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
+                item.put("port", device.getPort() != null ? device.getPort() : JSONObject.NULL);
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
diff --git a/app/src/main/res/layout/dialog_add_device.xml b/app/src/main/res/layout/dialog_add_device.xml
index 2191ae40f15a08fbbf23a12ecf13385f93704c35..81a30150d7571ceee23642940eb8de0db9c7cb25 100644
--- a/app/src/main/res/layout/dialog_add_device.xml
+++ b/app/src/main/res/layout/dialog_add_device.xml
@@ -20,26 +20,44 @@
         <com.google.android.material.textfield.TextInputEditText
             android:id="@+id/deviceNameInput"
             android:layout_width="match_parent"
             android:layout_height="wrap_content"
             android:inputType="textCapWords"
             android:maxLines="1" />
     </com.google.android.material.textfield.TextInputLayout>
 
     <com.google.android.material.textfield.TextInputLayout
         android:id="@+id/deviceIpLayout"
         style="@style/Widget.Material3.TextInputLayout.OutlinedBox"
         android:layout_width="match_parent"
         android:layout_height="wrap_content"
         android:layout_marginTop="12dp"
         android:hint="@string/device_ip_hint"
         app:boxStrokeColor="@color/primary">
 
         <com.google.android.material.textfield.TextInputEditText
             android:id="@+id/deviceIpInput"
             android:layout_width="match_parent"
             android:layout_height="wrap_content"
             android:inputType="text"
             android:maxLines="1"
             android:hint="192.168.0.10" />
     </com.google.android.material.textfield.TextInputLayout>
+
+    <com.google.android.material.textfield.TextInputLayout
+        android:id="@+id/devicePortLayout"
+        style="@style/Widget.Material3.TextInputLayout.OutlinedBox"
+        android:layout_width="match_parent"
+        android:layout_height="wrap_content"
+        android:layout_marginTop="12dp"
+        android:hint="@string/device_port_hint"
+        app:boxStrokeColor="@color/primary">
+
+        <com.google.android.material.textfield.TextInputEditText
+            android:id="@+id/devicePortInput"
+            android:layout_width="match_parent"
+            android:layout_height="wrap_content"
+            android:inputType="number"
+            android:maxLines="1"
+            android:hint="@string/device_port_placeholder" />
+    </com.google.android.material.textfield.TextInputLayout>
 </LinearLayout>
diff --git a/app/src/main/res/values/strings.xml b/app/src/main/res/values/strings.xml
index e93d9aab5a012ec04aea5588b4dba37672d1a5db..0004a7d7e033293b76a9a5d65ea2aec32074ca3a 100644
--- a/app/src/main/res/values/strings.xml
+++ b/app/src/main/res/values/strings.xml
@@ -1,35 +1,22 @@
 <resources>
     <string name="app_name">Light Control</string>
     <string name="app_logo">Логотип приложения</string>
     <string name="app_tagline">Управляйте устройствами в несколько кликов</string>
     <string name="add_device">Добавить устройство</string>
     <string name="device_list_title">Мои устройства</string>
     <string name="device_list_empty">Здесь появятся ваши устройства после добавления</string>
     <string name="device_name_hint">Название устройства</string>
     <string name="device_ip_hint">IP адрес устройства</string>
+    <string name="device_port_hint">Порт (необязательно)</string>
+    <string name="device_port_placeholder">8080</string>
     <string name="error_empty_name">Введите название устройства</string>
     <string name="error_empty_ip">Введите IP адрес</string>
+    <string name="error_invalid_port">Укажите порт от 1 до 65535</string>
     <string name="edit_device">Редактировать устройство</string>
     <string name="rename_device">Переименовать</string>
     <string name="delete_device">Удалить устройство</string>
     <string name="delete_device_confirmation">Удалить %1$s?</string>
     <string name="cancel">Отмена</string>
     <string name="save">Сохранить</string>
-<<<<<<< ours
-=======
     <string name="delete">Удалить</string>
-        <!-- Add the missing strings from the error log below -->
-        <string name="next">Next</string>
-        <string name="previous">Previous</string>
-        <string name="action_settings">Settings</string>
-        <string name="first_fragment_label">First Fragment</string>
-        <string name="second_fragment_label">Second Fragment</string>
-        <string name="lorem_ipsum">
-            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent
-            libero.
-            Sed cursus ante dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis
-            sagittis ipsum.
-            Praesent mauris. Fusce nec tellus sed augue semper porta. Mauris massa.
-        </string>
->>>>>>> theirs
 </resources>
 
EOF
)