# Lớp 12C4 — Album kỷ niệm

Flutter Web app hiển thị ảnh và video lớp 12C4. Visitor dùng mật khẩu `12c4`, admin dùng `admin12c4` để upload thêm.

## Setup Cloudinary (1 lần duy nhất)

### 1. Cho phép public list-by-tag

Vào [Cloudinary Console](https://console.cloudinary.com/) → **Settings → Security → Restricted media types**:

- **Bỏ tick** "Resource list" cho cả `image`, `video`, `raw`.
- Save.

Cho phép endpoint `https://res.cloudinary.com/<cloud>/<resource_type>/list/<tag>.json` hoạt động không cần auth.

### 2. Tạo Unsigned Upload Preset

**Settings → Upload → Upload presets → Add upload preset**:

| Field | Value |
|---|---|
| Name | `class12c4_unsigned` |
| Signing Mode | **Unsigned** |
| Folder | (để trống — client truyền `folder` theo từng upload) |
| Tags | `class12c4` |
| Allowed formats | `jpg,jpeg,png,gif,webp,mp4,mov,webm,m4v,json` |
| Max file size | 50000000 (50 MB) — tuỳ chọn |
| Overwrite | true (cho phép ghi đè `meta/youtube.json`) |
| Use filename | true |
| Unique filename | true |

Save.

### 3. Gắn tag cho 76 ảnh cũ (1 lần)

Các ảnh upload trước đây không có tag `class12c4` nên sẽ không xuất hiện trong list. Chạy:

```bash
export CLOUDINARY_URL='cloudinary://<api_key>:<api_secret>@phucnguyen'
bash tool/tag_existing.sh
```

Script dùng Admin API gắn tag `class12c4` cho 76 ảnh trong folder `Images`. Sau khi xong có thể `unset CLOUDINARY_URL`.

## Chạy local

```bash
flutter pub get
flutter run -d chrome
```

- Mật khẩu viewer: `12c4` → trang xem ảnh/video.
- Mật khẩu admin: `admin12c4` → trang upload + thêm YouTube embed.

## Build

```bash
flutter build web
# Deploy folder build/web/ lên Netlify / Vercel / GitHub Pages
```

## Lưu ý bảo mật

Mật khẩu nằm trong client bundle (chỉ ẩn UI). Upload preset là **unsigned** — ai biết tên preset cũng có thể upload. Mitigate bằng `allowed_formats` + `max_file_size` trong preset. Muốn bảo mật thực sự → cần backend ký request (chưa implement).
