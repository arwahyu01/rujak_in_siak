import { useEffect, useState } from 'react';
import Sidebar from '@/Components/Layout/Sidebar';
import Navbar from '@/Components/Layout/Navbar';
import Footer from '@/Components/Layout/Footer';
import FlashMessages from '@/Components/UI/FlashMessages';

export default function AdminLayout({ children }) {
    const [open, setOpen] = useState(() => (typeof window === 'undefined' ? true : window.innerWidth >= 1200));

    useEffect(() => {
        const onResize = () => {
            if (window.innerWidth >= 1200) setOpen(true);
            else setOpen(false);
        };
        window.addEventListener('resize', onResize);
        return () => window.removeEventListener('resize', onResize);
    }, []);

    return (
        <div className="min-h-screen bg-lightPrimary dark:bg-navy-900">
            <FlashMessages />
            <Sidebar open={open} onClose={() => setOpen(false)} />
            {open ? (
                <button
                    type="button"
                    aria-label="Tutup menu"
                    onClick={() => setOpen(false)}
                    className="fixed inset-0 z-50 bg-navy-900/40 backdrop-blur-sm xl:hidden"
                />
            ) : null}
            <div className="min-h-screen xl:ml-[290px]">
                <div className="mx-auto max-w-[1700px] px-3 pb-2 pt-3 md:px-5">
                    <Navbar onOpenSidebar={() => setOpen(true)} />
                    <main className="py-5">{children}</main>
                    <Footer />
                </div>
            </div>
        </div>
    );
}
