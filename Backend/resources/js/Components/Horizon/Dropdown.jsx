import { useEffect, useRef, useState } from 'react';

export default function Dropdown({ button, children, classNames = '', animation = '' }) {
    const ref = useRef(null);
    const [open, setOpen] = useState(false);

    useEffect(() => {
        function handleClickOutside(event) {
            if (ref.current && !ref.current.contains(event.target)) {
                setOpen(false);
            }
        }
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    return (
        <div ref={ref} className="relative flex">
            <button type="button" className="flex" onClick={() => setOpen((value) => !value)}>
                {button}
            </button>
            <div
                className={`absolute z-50 ${classNames} ${
                    animation || 'origin-top-right transition-all duration-200 ease-out'
                } ${open ? 'pointer-events-auto scale-100 opacity-100' : 'pointer-events-none scale-95 opacity-0'}`}
            >
                {children}
            </div>
        </div>
    );
}
