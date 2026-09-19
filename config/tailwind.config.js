module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}' // 👈 이 구문이 포함되어 있는지 확인!
  ],
  // ...
}