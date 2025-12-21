<?php
// resto_api/utils/helpers.php

if (!function_exists('sendResponse')) {
    /**
     * Helper function to send JSON responses.
     *
     * @param bool $success Indicates if the operation was successful.
     * @param string $message A descriptive message for the response.
     * @param mixed $data Optional data to include in the response.
     * @param int $httpCode The HTTP status code to send.
     */
    function sendResponse($success, $message, $data = null, $httpCode = 200) {
        http_response_code($httpCode);
        header('Content-Type: application/json');
        echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
        exit;
    }
}
