import { Link } from '@inertiajs/react';
import { MdArrowBack, MdErrorOutline, MdHome } from 'react-icons/md';
import Button from '@/Components/UI/Button';

const messages = {
    403: {
        title: 'Akses ditolak',
        description: 'Akun Anda tidak memiliki permission untuk membuka halaman atau melakukan aksi ini.',
    },
    404: {
        title: 'Halaman tidak ditemukan',
        description: 'Alamat yang Anda buka tidak tersedia atau data sudah tidak ada.',
    },
    419: {
        title: 'Sesi kedaluwarsa',
        description: 'Sesi Anda telah berakhir. Silakan masuk kembali untuk melanjutkan.',
    },
    429: {
        title: 'Terlalu banyak permintaan',
        description: 'Tunggu sebentar sebelum mencoba lagi.',
    },
    500: {
        title: 'Terjadi kesalahan server',
        description: 'Permintaan tidak dapat diproses. Hubungi administrator bila masalah berlanjut.',
    },
    503: {
        title: 'Layanan sedang maintenance',
        description: 'Back-office sedang tidak tersedia. Coba kembali beberapa saat lagi.',
    },
};

export default function ErrorPage({ status = 404 }) {
    const message = messages[status] || messages[500];

    return (
        <div className="flex min-h-screen items-center justify-center bg-lightPrimary px-5 dark:bg-navy-900">
            <div className="w-full max-w-lg rounded-[24px] bg-white p-8 text-center shadow-3xl shadow-shadow-500 dark:bg-navy-800 dark:shadow-none">
                <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-red-50 text-red-500 dark:bg-red-500/10 dark:text-red-400">
                    <MdErrorOutline className="h-8 w-8" />
                </div>
                <p className="mt-5 font-poppins text-4xl font-extrabold text-brand-500 dark:text-brand-300">{status}</p>
                <h1 className="mt-2 font-poppins text-xl font-bold text-navy-700 dark:text-white">{message.title}</h1>
                <p className="mt-2 text-sm leading-6 text-gray-600 dark:text-gray-400">{message.description}</p>
                <div className="mt-6 flex flex-col justify-center gap-2 sm:flex-row">
                    <Link href="/dashboard">
                        <Button>
                            <MdHome className="h-4 w-4" />
                            Ke dashboard
                        </Button>
                    </Link>
                    <Button variant="secondary" onClick={() => window.history.back()}>
                        <MdArrowBack className="h-4 w-4" />
                        Kembali
                    </Button>
                </div>
                <p className="mt-6 text-[11px] text-gray-500 dark:text-gray-500">
                    RUJAK.IN.SIAK POS · Back-office
                </p>
            </div>
        </div>
    );
}
