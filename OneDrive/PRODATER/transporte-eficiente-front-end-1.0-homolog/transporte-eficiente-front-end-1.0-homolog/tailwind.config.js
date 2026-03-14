export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  important: true,
  theme: {
    extend: {
      colors: {
        primaryColor: 'var(--color-primary)',
        secondaryColor: 'var(--color-secondary)',
        errorColor: 'var(--color-error)',
      },
    },
  },
  plugins: [],
}
