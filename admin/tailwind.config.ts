import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          50:  '#e8eaf6',
          100: '#c5cae9',
          500: '#1a237e',
          600: '#151b6b',
          700: '#0f1457',
          800: '#0a0e44',
          900: '#060830',
        },
        amber: {
          400: '#fbbf24',
          500: '#f59e0b',
        },
      },
    },
  },
  plugins: [],
}

export default config
