interface Props {
  size?: number
  withText?: boolean
}

/** 첨탑 위의 십자가와 이정표(화살표)를 형상화한 로고 */
export function LogoMark({ size = 36 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" role="img" aria-label="스티플 로고">
      <rect width="64" height="64" rx="14" fill="#1f3a5f" />
      <path d="M32 6v10M27.5 10.5h9" stroke="#e0b95a" strokeWidth="3" strokeLinecap="round" />
      <path d="M32 18l10 20H22z" fill="#f6f4ef" />
      <rect x="22" y="38" width="20" height="18" fill="#f6f4ef" />
      <path d="M28 56V46a4 4 0 0 1 8 0v10z" fill="#1f3a5f" />
    </svg>
  )
}

export function Logo({ size = 36, withText = true }: Props) {
  return (
    <span className="logo">
      <LogoMark size={size} />
      {withText && (
        <span className="logo-text">
          <strong>스티플</strong>
          <small>Steeple</small>
        </span>
      )}
    </span>
  )
}
