import { useEffect, useState } from 'react';
import { usePage } from '@inertiajs/react';
import { HiCheckCircle, HiExclamationCircle, HiX } from 'react-icons/hi';

export default function FlashMessages() {
    const { flash } = usePage().props;
    const [messages, setMessages] = useState([]);

    useEffect(() => {
        const next = [];
        if (flash?.success) next.push({ id: `success-${flash.success}`, type: 'success', text: flash.success });
        if (flash?.error) next.push({ id: `error-${flash.error}`, type: 'error', text: flash.error });
        setMessages(next);
    }, [flash?.success, flash?.error]);

    useEffect(() => {
        if (messages.length === 0) return;
        const timer = setTimeout(() => setMessages([]), 6000);
        return () => clearTimeout(timer);
    }, [messages]);

    if (messages.length === 0) return null;

    return (
        <div className="fixed right-4 top-4 z-[120] flex w-[calc(100%-2rem)] max-w-sm flex-col gap-2">
            {messages.map((message) => (
                <div
                    key={message.id}
                    className={`toast-enter flex items-start gap-3 rounded-2xl border bg-white p-4 shadow-xl dark:bg-navy-800 ${
                        message.type === 'success'
                            ? 'border-green-200 dark:border-green-500/30'
                            : 'border-red-200 dark:border-red-500/30'
                    }`}
                >
                    {message.type === 'success' ? (
                        <HiCheckCircle className="mt-0.5 h-5 w-5 shrink-0 text-green-500" />
                    ) : (
                        <HiExclamationCircle className="mt-0.5 h-5 w-5 shrink-0 text-red-500" />
                    )}
                    <p className="flex-1 text-sm font-medium text-navy-700 dark:text-white">{message.text}</p>
                    <button
                        type="button"
                        onClick={() => setMessages((current) => current.filter((item) => item.id !== message.id))}
                        className="text-gray-400 transition hover:text-navy-700 dark:hover:text-white"
                        aria-label="Tutup notifikasi"
                    >
                        <HiX className="h-4 w-4" />
                    </button>
                </div>
            ))}
        </div>
    );
}
