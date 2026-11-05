export default function Card({ children, className = '', ...props }) {
    return (
        <div
            className={`relative flex flex-col rounded-[20px] bg-white bg-clip-border shadow-3xl shadow-shadow-500 dark:bg-navy-800 dark:text-white dark:shadow-none ${className}`}
            {...props}
        >
            {children}
        </div>
    );
}
