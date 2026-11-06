<?php

namespace App\Exceptions;

use RuntimeException;

class ApiException extends RuntimeException
{
    public function __construct(
        public readonly string $errorCode,
        string $message,
        public readonly int $status = 422,
        public readonly array $details = [],
        public readonly bool $retryable = false,
    ) {
        parent::__construct($message);
    }

    public static function conflict(string $code, string $message, array $details = []): self
    {
        return new self($code, $message, 409, $details, false);
    }

    public static function blocked(string $code, string $message, array $details = []): self
    {
        return new self($code, $message, 409, $details, true);
    }

    public static function notFound(string $message = 'Data tidak ditemukan.'): self
    {
        return new self('NOT_FOUND', $message, 404);
    }

    public static function forbidden(string $message = 'Anda tidak memiliki hak untuk tindakan ini.'): self
    {
        return new self('FORBIDDEN', $message, 403);
    }
}
