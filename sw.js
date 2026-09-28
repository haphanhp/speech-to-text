// Service worker tối giản - chỉ để Chrome chấp nhận cài đặt PWA.
// Không cache gì, luôn lấy trực tiếp từ mạng.
self.addEventListener('install', function(event){
  self.skipWaiting();
});
self.addEventListener('activate', function(event){
  self.clients.claim();
});
self.addEventListener('fetch', function(event){
  event.respondWith(fetch(event.request));
});
