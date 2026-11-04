import { HashRouter, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { Home } from './pages/Home'
import { Explore } from './pages/Explore'
import { ChurchDetail } from './pages/ChurchDetail'
import { Denominations } from './pages/Denominations'
import { Heresy } from './pages/Heresy'
import { NotFound } from './pages/NotFound'

// GitHub Pages는 서버 라우팅이 없으므로 HashRouter(#/경로)를 사용합니다.
export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="explore" element={<Explore />} />
          <Route path="church/:id" element={<ChurchDetail />} />
          <Route path="denominations" element={<Denominations />} />
          <Route path="heresy" element={<Heresy />} />
          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </HashRouter>
  )
}
