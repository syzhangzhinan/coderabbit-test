// eslint.config.js — 测试用最小 ESLint Flat Config
//
// 仅启用关键规则便于快速观察：
//   no-unused-vars / no-console / eqeqeq / array-callback-return
//
// 真实项目可继续扩展（@typescript-eslint, eslint-plugin-import 等）

export default [
  {
    files: ['**/*.{js,jsx,ts,tsx,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module'
    },
    rules: {
      'no-unused-vars': ['error', {args: 'none'}],
      'no-console': 'warn',
      eqeqeq: ['error', 'always'],
      'array-callback-return': 'error'
    }
  }
]
