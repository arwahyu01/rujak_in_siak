<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="theme-color" content="#422AFB">
    <title inertia>{{ config('app.name', 'RUJAK.IN.SIAK POS') }}</title>
    @viteReactRefresh
    @vite(['resources/css/app.css', 'resources/js/app.jsx'])
    @inertiaHead
</head>
<body class="bg-lightPrimary font-dm text-navy-700 antialiased dark:bg-navy-900 dark:text-white">
    @inertia
</body>
</html>
