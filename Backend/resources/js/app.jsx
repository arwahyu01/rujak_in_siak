import '../css/app.css';
import './bootstrap';

import { createInertiaApp } from '@inertiajs/react';
import { createRoot } from 'react-dom/client';

const storedTheme = typeof window !== 'undefined' ? localStorage.getItem('rujak-theme') : null;
if (storedTheme === 'dark' || (!storedTheme && typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark');
} else {
    document.documentElement.classList.remove('dark');
}

createInertiaApp({
    title: (title) => (title ? `${title} - RUJAK.IN.SIAK POS` : 'RUJAK.IN.SIAK POS'),
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true });
        const page = pages[`./Pages/${name}.jsx`];
        if (!page) {
            throw new Error(`Halaman Inertia tidak ditemukan: ${name}`);
        }
        return page;
    },
    setup({ el, App, props }) {
        createRoot(el).render(<App {...props} />);
    },
    progress: {
        color: '#422AFB',
        showSpinner: false,
    },
});
