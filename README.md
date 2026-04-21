# exter-atmrobbery

Universal, modular, and security-focused **FiveM ATM Robbery** resource.

Script ini sudah di-refactor supaya kompatibel lintas ekosistem FiveM dan mudah dipublish untuk server publik.

---

## ✨ Fitur Utama

- ✅ **Framework Auto Detection**
  - `qb-core`
  - `es_extended`
  - `qbx_core`
  - `standalone` fallback
- ✅ **Inventory Auto Detection**
  - `qb-inventory`
  - `qs-inventory`
  - `ox_inventory`
  - `esx_inventory` (fallback via framework bridge)
- ✅ **Dispatch Auto Detection**
  - `ps-dispatch`
  - `cd_dispatch`
  - `exter-dispatch`
  - fallback aman jika tidak ada dispatch
- ✅ **Target & Interaction**
  - `qb-target`
  - `ox_target`
  - mode `drawtext` via config
- ✅ **Security Layer (Server-Side First)**
  - anti spam throttling
  - player cooldown
  - ATM cooldown
  - server-side job validation
  - server-side distance check
  - item validation + remove item validation
  - anti event abuse / anti item dupe basic flow
- ✅ **Modular Architecture**
  - `bridges/framework.lua`
  - `bridges/inventory.lua`
  - `bridges/dispatch.lua`

---

## 📁 Struktur Resource

```txt
exter-atmrobbery/
├─ fxmanifest.lua
├─ config.lua
├─ client.lua
├─ server.lua
├─ bridges/
│  ├─ framework.lua
│  ├─ inventory.lua
│  └─ dispatch.lua
└─ stream/
```

---

## 🚀 Instalasi

1. Copy folder resource ke server:
   - `resources/[local]/exter-atmrobbery`
2. Pastikan dependency kamu sudah jalan (`qb-core` / `es_extended` / `qbx_core`, dll sesuai stack).
3. Tambahkan ke `server.cfg`:

```cfg
ensure exter-atmrobbery
```

4. Restart server.

---

## ⚙️ Konfigurasi Dasar (`config.lua`)

Default disarankan pakai auto detection:

```lua
Config.Framework = 'auto'
Config.Inventory = 'auto'
Config.Dispatch = 'auto'
Config.Target = 'auto'
Config.InteractionMode = 'target' -- or 'drawtext'
```

### Pilihan penting

- `Config.Reward` → minimum/maximum reward + tipe uang.
- `Config.Items` → nama item rope + jumlah yang dipakai.
- `Config.Timers` → progress, cooldown, anti-spam interval.
- `Config.Security` → max distance, allow/deny job list.
- `Config.Debug` → log debug ke console.

---

## 🧩 Cara Kerja Singkat

1. Player interaksi ke ATM (via target/drawtext).
2. Server validasi job + cooldown + distance + item rope.
3. Rope dikonsumsi (server-side) lalu proses tarik ATM.
4. Dispatch alert dipanggil (jika resource dispatch tersedia).
5. Player crack ATM, server validasi lagi.
6. Reward diberikan melalui inventory/framework bridge.

---

## 🔐 Security Notes

Resource ini didesain dengan prinsip **never trust client**.

- Semua aksi penting diverifikasi di server event.
- Event spam ditahan dengan throttle (`antiSpamMs`).
- Cooldown per-player dan per-ATM mencegah farm abuse.
- Validasi distance mengurangi remote trigger exploit.
- Reward hanya keluar setelah validasi final crack.

> Tetap disarankan tambah protection eksternal (anti-cheat/event protector) di production server besar.

---

## 🧪 Testing Checklist (Recommended di server kamu)

- [ ] Test mode `target` dengan `qb-target`
- [ ] Test mode `target` dengan `ox_target`
- [ ] Test mode `drawtext`
- [ ] Test reward normal cash & black money
- [ ] Test tanpa item rope (harus gagal)
- [ ] Test spam trigger event (harus diblok/throttle)
- [ ] Test cooldown player/ATM
- [ ] Test dispatch integration sesuai resource yang dipakai

---

## 🛠 Compatibility Matrix

| Component  | Supported |
|------------|-----------|
| Framework  | qb-core, es_extended, qbx_core, standalone |
| Inventory  | ox_inventory, qb-inventory, qs-inventory, framework fallback |
| Dispatch   | ps-dispatch, cd_dispatch, exter-dispatch, standalone |
| Target     | qb-target, ox_target, drawtext mode |

---

## ❗ Troubleshooting

### Script tidak detect framework
- Cek nama resource benar (`qb-core`, `es_extended`, `qbx_core`).
- Atur manual di config:

```lua
Config.Framework = 'qb-core' -- contoh
```

### Tidak bisa add/remove item
- Pastikan inventory resource kamu `started`.
- Coba set manual:

```lua
Config.Inventory = 'ox_inventory' -- contoh
```

### Dispatch tidak jalan
- Cek resource dispatch aktif.
- Set manual:

```lua
Config.Dispatch = 'ps-dispatch' -- contoh
```

### Interaksi target tidak muncul
- Cek `Config.InteractionMode = 'target'`
- Cek `qb-target` / `ox_target` status.
- Jika perlu fallback:

```lua
Config.InteractionMode = 'drawtext'
```

---

## 🤝 Contributing

PR welcome untuk:
- adapter dispatch/inventory/framework baru,
- peningkatan security,
- optimasi performa,
- dokumentasi tambahan.

---

## 📄 License

Lihat file `LICENSE` di repository ini.
