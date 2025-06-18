<?php
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Method Not Allowed"]);
    exit;
}

// Load POST data
$data = json_decode(file_get_contents("php://input"), true);
$to = $data['to'] ?? null;
$subject = $data['subject'] ?? null;
$message = $data['message'] ?? null;

if (!$to || !$subject || !$message) {
    http_response_code(400);
    echo json_encode(["error" => "Missing required fields"]);
    exit;
}

// Function to generate beautiful HTML email template
function generateFeedbackEmailHTML($message) {
    // Parse the message to extract feedback details
    $lines = explode("\n", trim($message));
    $feedbackData = [];
    
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line)) continue;
        
        if (strpos($line, 'Name:') === 0) {
            $feedbackData['name'] = trim(substr($line, 5));
        } elseif (strpos($line, 'Email:') === 0) {
            $feedbackData['email'] = trim(substr($line, 6));
        } elseif (strpos($line, 'Purpose:') === 0) {
            $feedbackData['purpose'] = trim(substr($line, 8));
        } elseif (strpos($line, 'Rating:') === 0) {
            $feedbackData['rating'] = trim(substr($line, 7));
        } elseif (strpos($line, 'Comment:') === 0) {
            $feedbackData['comment'] = trim(substr($line, 8));
        }
    }
    
    $name = $feedbackData['name'] ?? 'Anonymous';
    $email = $feedbackData['email'] ?? 'No email provided';
    $purpose = $feedbackData['purpose'] ?? 'General feedback';
    $rating = $feedbackData['rating'] ?? 'Not provided';
    $comment = $feedbackData['comment'] ?? 'No comment provided';
    
    // Generate star rating HTML
    $ratingNumber = (int) preg_replace('/[^0-9]/', '', $rating);
    $stars = '';
    for ($i = 1; $i <= 5; $i++) {
        if ($i <= $ratingNumber) {
            $stars .= '<span style="color: #FFD700; font-size: 20px;">★</span>';
        } else {
            $stars .= '<span style="color: #E0E0E0; font-size: 20px;">★</span>';
        }
    }
    
    return '
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SnapWise Feedback</title>
        <style>
            body {
                font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
                background-color: #f4f4f4;
            }
            .email-container {
                max-width: 600px;
                margin: 0 auto;
                background-color: #ffffff;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: 600;
            }
            .header p {
                margin: 10px 0 0 0;
                opacity: 0.9;
                font-size: 16px;
            }
            .content {
                padding: 30px 20px;
            }
            .feedback-section {
                background-color: #f8f9fa;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                border-left: 4px solid #667eea;
            }
            .feedback-item {
                margin-bottom: 15px;
            }
            .feedback-label {
                font-weight: 600;
                color: #555;
                margin-bottom: 5px;
                font-size: 14px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            .feedback-value {
                color: #333;
                font-size: 16px;
                padding: 8px 12px;
                background-color: white;
                border-radius: 4px;
                border: 1px solid #e0e0e0;
            }
            .rating-stars {
                text-align: center;
                padding: 10px 0;
            }
            .comment-section {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 6px;
                padding: 15px;
                margin-top: 10px;
            }
            .footer {
                background-color: #f8f9fa;
                padding: 20px;
                text-align: center;
                border-top: 1px solid #e9ecef;
            }
            .footer p {
                margin: 0;
                color: #6c757d;
                font-size: 14px;
            }
            .logo {
                font-size: 24px;
                font-weight: bold;
                margin-bottom: 10px;
            }
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <div class="logo">💰 SnapWise</div>
                <h1>New Feedback Received</h1>
                <p>You have received new feedback from a user</p>
            </div>
            
            <div class="content">
                <div class="feedback-section">
                    <div class="feedback-item">
                        <div class="feedback-label">Name</div>
                        <div class="feedback-value">' . htmlspecialchars($name) . '</div>
                    </div>
                    
                    <div class="feedback-item">
                        <div class="feedback-label">Email</div>
                        <div class="feedback-value">' . htmlspecialchars($email) . '</div>
                    </div>
                    
                    <div class="feedback-item">
                        <div class="feedback-label">Purpose</div>
                        <div class="feedback-value">' . htmlspecialchars($purpose) . '</div>
                    </div>
                    
                    <div class="feedback-item">
                        <div class="feedback-label">Rating</div>
                        <div class="feedback-value">
                            <div class="rating-stars">
                                ' . $stars . '
                            </div>
                            <div style="text-align: center; margin-top: 5px; color: #666;">
                                ' . htmlspecialchars($rating) . '
                            </div>
                        </div>
                    </div>
                    
                    <div class="feedback-item">
                        <div class="feedback-label">Comment</div>
                        <div class="comment-section">
                            ' . htmlspecialchars($comment) . '
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="footer">
                <p>This feedback was sent from the SnapWise application</p>
                <p>© 2024 SnapWise. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>';
}

// Function to generate confirmation email for user
function generateConfirmationEmailHTML($name, $purpose) {
    return '
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Feedback Confirmation - SnapWise</title>
        <style>
            body {
                font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
                background-color: #f4f4f4;
            }
            .email-container {
                max-width: 600px;
                margin: 0 auto;
                background-color: #ffffff;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: 600;
            }
            .header p {
                margin: 10px 0 0 0;
                opacity: 0.9;
                font-size: 16px;
            }
            .content {
                padding: 30px 20px;
            }
            .confirmation-section {
                background-color: #f8f9fa;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                border-left: 4px solid #28a745;
            }
            .footer {
                background-color: #f8f9fa;
                padding: 20px;
                text-align: center;
                border-top: 1px solid #e9ecef;
            }
            .footer p {
                margin: 0;
                color: #6c757d;
                font-size: 14px;
            }
            .logo {
                font-size: 24px;
                font-weight: bold;
                margin-bottom: 10px;
            }
            .checkmark {
                font-size: 48px;
                color: #28a745;
                margin-bottom: 20px;
            }
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <div class="logo">💰 SnapWise</div>
                <h1>Feedback Received!</h1>
                <p>Thank you for your valuable feedback</p>
            </div>
            
            <div class="content">
                <div class="confirmation-section">
                    <div style="text-align: center;">
                        <div class="checkmark">✓</div>
                        <h2 style="color: #28a745; margin-bottom: 15px;">Thank you, ' . htmlspecialchars($name) . '!</h2>
                        <p style="font-size: 16px; line-height: 1.6;">
                            We have successfully received your feedback regarding <strong>' . htmlspecialchars($purpose) . '</strong>.
                        </p>
                        <p style="font-size: 16px; line-height: 1.6;">
                            Your input is valuable to us and helps us improve SnapWise for everyone. We will review your feedback and get back to you if needed.
                        </p>
                        <p style="font-size: 16px; line-height: 1.6;">
                            Thank you for being part of the SnapWise community!
                        </p>
                    </div>
                </div>
            </div>
            
            <div class="footer">
                <p>This is an automated confirmation from the SnapWise application</p>
                <p>© 2024 SnapWise. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>';
}

// PHPMailer setup
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'PHPMailer/src/Exception.php';
require 'PHPMailer/src/PHPMailer.php';
require 'PHPMailer/src/SMTP.php';

$mail = new PHPMailer(true);

try {
    // Parse the message to extract user email for confirmation
    $lines = explode("\n", trim($message));
    $userEmail = null;
    $userName = null;
    $userPurpose = null;
    
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line)) continue;
        
        if (strpos($line, 'Email:') === 0) {
            $userEmail = trim(substr($line, 6));
        } elseif (strpos($line, 'Name:') === 0) {
            $userName = trim(substr($line, 5));
        } elseif (strpos($line, 'Purpose:') === 0) {
            $userPurpose = trim(substr($line, 8));
        }
    }

    // SMTP config
    $mail->isSMTP();
    $mail->Host       = 'mail.intrusion101.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'snapwise@intrusion101.com';
    $mail->Password   = '#+U^L0r!baSF';
    $mail->SMTPSecure = 'ssl';
    $mail->Port       = 465;

    // 1. Send feedback to admin (snapwiseofficial25@gmail.com)
    $mail->clearAddresses();
    $mail->setFrom('snapwise@intrusion101.com', 'SnapWise Feedback System');
    $mail->addAddress($to); // This is snapwiseofficial25@gmail.com
    $mail->isHTML(true);
    $mail->Subject = $subject;
    $mail->Body    = generateFeedbackEmailHTML($message);

    $mail->send();

    // 2. Send confirmation email to user (if email is provided)
    if ($userEmail && $userName && $userPurpose) {
        $mail->clearAddresses();
        $mail->setFrom('snapwise@intrusion101.com', 'SnapWise Feedback System');
        $mail->addAddress($userEmail);
        $mail->isHTML(true);
        $mail->Subject = 'Thank you for your feedback - SnapWise';
        $mail->Body    = generateConfirmationEmailHTML($userName, $userPurpose);

        $mail->send();
    }

    echo json_encode(["success" => true, "message" => "Feedback sent successfully"]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["error" => "Email sending failed: {$mail->ErrorInfo}"]);
}
?> 