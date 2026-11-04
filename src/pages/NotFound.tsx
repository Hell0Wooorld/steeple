import { Link } from 'react-router-dom'

export function NotFound() {
  return (
    <div className="page">
      <h1>길을 잃으셨나요?</h1>
      <p className="lead">찾으시는 페이지가 없습니다.</p>
      <Link className="btn btn-primary" to="/">
        홈으로 돌아가기
      </Link>
    </div>
  )
}
