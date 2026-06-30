<template>
  <footer class="app-footer">
    <p>&copy; {{ currentYear }} AI Reviewer Test Store</p>
    <div class="footer-links">
      <a href="/terms">条款</a>
      <a href="/privacy">隐私</a>
    </div>
  </footer>
</template>

<script setup lang="ts">
const currentYear = new Date().getFullYear()
</script>
