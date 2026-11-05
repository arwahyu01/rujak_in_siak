import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.jsx'],
            refresh: true,
        }),
        react(),
    ],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, 'resources/js'),
            assets: path.resolve(__dirname, 'resources/js/assets'),
            components: path.resolve(__dirname, 'resources/js/Components'),
            layouts: path.resolve(__dirname, 'resources/js/Layouts'),
            pages: path.resolve(__dirname, 'resources/js/Pages'),
            variables: path.resolve(__dirname, 'resources/js/variables'),
        },
    },
    server: {
        watch: {
            ignored: ['**/storage/framework/views/**'],
        },
    },
});
