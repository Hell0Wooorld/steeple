import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// 상대 경로 base + HashRouter 조합이라 GitHub Pages의 어떤 저장소 경로에서도 동작합니다.
export default defineConfig({
  base: './',
  plugins: [react()],
})
