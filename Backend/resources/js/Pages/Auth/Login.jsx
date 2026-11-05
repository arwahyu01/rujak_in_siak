import { Head, useForm, usePage } from '@inertiajs/react';
import { HiOutlineLockClosed, HiOutlineMail } from 'react-icons/hi';
import authImage from '@/assets/img/auth/auth.png';
import InputField from '@/Components/UI/InputField';
import Checkbox from '@/Components/UI/Checkbox';
import Button from '@/Components/UI/Button';

export default function Login() {
    const { flash } = usePage().props;
    const { data, setData, post, processing, errors, reset } = useForm({
        email: '',
        password: '',
        remember: false,
    });

    const submit = (event) => {
        event.preventDefault();
        post('/login', { onFinish: () => reset('password') });
    };

    return (
        <>
            <Head title="Masuk" />
            <div className="relative min-h-screen bg-lightPrimary dark:bg-navy-900">
                <div className="mx-auto flex min-h-screen w-full max-w-[1600px] flex-col lg:flex-row">
                    <div className="flex flex-1 items-center justify-center px-5 py-12 sm:px-8 lg:px-16">
                        <div className="w-full max-w-[420px]">
                            <div className="mb-10 flex items-center gap-3">
                                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-400 to-brand-700 font-poppins text-2xl font-extrabold text-white shadow-lg shadow-brand-500/30">
                                    R
                                </div>
                                <div>
                                    <p className="font-poppins text-lg font-extrabold tracking-tight text-navy-700 dark:text-white">
                                        RUJAK.IN.SIAK
                                    </p>
                                    <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-brand-500 dark:text-brand-300">
                                        POS Back-office
                                    </p>
                                </div>
                            </div>

                            <h1 className="font-poppins text-3xl font-bold text-navy-700 dark:text-white">
                                Masuk ke back-office
                            </h1>
                            <p className="mt-2 text-sm leading-6 text-gray-600 dark:text-gray-400">
                                Kelola katalog, verifikasi pembayaran non-tunai, pantau shift, dan tinjau laporan penjualan.
                            </p>

                            {flash?.error ? (
                                <div className="mt-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                                    {flash.error}
                                </div>
                            ) : null}
                            {flash?.success ? (
                                <div className="mt-6 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-medium text-green-700 dark:border-green-500/30 dark:bg-green-500/10 dark:text-green-300">
                                    {flash.success}
                                </div>
                            ) : null}

                            <form onSubmit={submit} className="mt-8 space-y-5">
                                <div className="relative">
                                    <InputField
                                        id="email"
                                        label="Email atau username"
                                        type="text"
                                        autoComplete="username"
                                        autoFocus
                                        required
                                        value={data.email}
                                        onChange={(event) => setData('email', event.target.value)}
                                        placeholder="nama@rujakinsiak.id"
                                        error={errors.email}
                                    />
                                    <HiOutlineMail className="pointer-events-none absolute right-3 top-[42px] h-5 w-5 text-gray-400" />
                                </div>

                                <div className="relative">
                                    <InputField
                                        id="password"
                                        label="Password"
                                        type="password"
                                        autoComplete="current-password"
                                        required
                                        value={data.password}
                                        onChange={(event) => setData('password', event.target.value)}
                                        placeholder="Masukkan password"
                                        error={errors.password}
                                    />
                                    <HiOutlineLockClosed className="pointer-events-none absolute right-3 top-[42px] h-5 w-5 text-gray-400" />
                                </div>

                                <div className="flex items-center justify-between">
                                    <Checkbox
                                        id="remember"
                                        label="Ingat saya"
                                        checked={data.remember}
                                        onChange={(event) => setData('remember', event.target.checked)}
                                    />
                                    <span className="text-xs text-gray-500 dark:text-gray-400">Sesi aman Laravel</span>
                                </div>

                                <Button type="submit" size="lg" className="w-full" disabled={processing}>
                                    {processing ? 'Memproses…' : 'Masuk'}
                                </Button>
                            </form>

                            <div className="mt-8 rounded-2xl border border-gray-200 bg-white p-4 text-xs leading-5 text-gray-600 dark:border-white/10 dark:bg-navy-800 dark:text-gray-400">
                                <p className="font-bold text-navy-700 dark:text-white">Akses terbatas</p>
                                <p className="mt-1">
                                    Web back-office hanya untuk Owner, Admin, dan Supervisor yang memiliki permission. Akun kasir tetap
                                    menggunakan aplikasi Android untuk transaksi POS.
                                </p>
                            </div>

                            <p className="mt-8 text-center text-xs text-gray-500 dark:text-gray-500">
                                © {new Date().getFullYear()} Rujak In Siak. UI berbasis Horizon UI (MIT).
                            </p>
                        </div>
                    </div>

                    <div className="relative hidden flex-1 lg:block">
                        <div
                            className="absolute inset-0 bg-cover bg-center"
                            style={{ backgroundImage: `url(${authImage})` }}
                        />
                        <div className="absolute inset-0 bg-gradient-to-t from-navy-900/80 via-navy-900/20 to-transparent" />
                        <div className="absolute bottom-12 left-12 right-12 rounded-[24px] bg-white/10 p-6 text-white backdrop-blur-md">
                            <p className="text-xs font-bold uppercase tracking-[0.24em] text-brand-100">
                                Offline-first POS
                            </p>
                            <p className="mt-2 font-poppins text-2xl font-bold leading-tight">
                                Transaksi tetap berjalan di perangkat. Back-office menjaga data tetap terkendali.
                            </p>
                            <p className="mt-3 text-sm leading-6 text-white/80">
                                Pembayaran non-tunai diverifikasi dengan pemisahan tugas, alasan, dan audit trail yang dapat ditelusuri.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </>
    );
}
