"""
Notification Service for SafariSalama
Handles emergency alerts, trip notifications, and user communications
"""
from typing import List, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class NotificationService:
    """
    Service to handle sending notifications via SMS, Push notifications, and Email
    Currently uses mock implementation - integrate with real services:
    - SMS: Twilio API
    - Push: Firebase Cloud Messaging (FCM)
    - Email: SendGrid or similar
    """

    @staticmethod
    def send_emergency_alert(
        alert_id: str,
        user_id: str,
        latitude: float,
        longitude: float,
        alert_type: str,
        emergency_contacts: List[str] = None,
        nearby_drivers: List[str] = None,
        sacco_admin_id: str = None,
    ):
        """
        Send emergency alert notifications to multiple recipients
        
        Args:
            alert_id: Emergency alert ID
            user_id: User who triggered alert
            latitude: Alert location latitude
            longitude: Alert location longitude
            alert_type: Type of alert (accident, theft, harassment, etc)
            emergency_contacts: List of phone numbers to notify
            nearby_drivers: List of driver IDs to notify
            sacco_admin_id: SACCO admin ID to notify
        """
        try:
            # Notify emergency contacts via SMS
            if emergency_contacts:
                NotificationService._send_emergency_sms(
                    emergency_contacts, alert_id, alert_type, latitude, longitude
                )

            # Notify nearby drivers via push notification
            if nearby_drivers:
                NotificationService._send_driver_push_notification(
                    nearby_drivers, alert_id, alert_type, user_id, latitude, longitude
                )

            # Notify SACCO admin
            if sacco_admin_id:
                NotificationService._send_admin_notification(
                    sacco_admin_id, alert_id, alert_type, user_id
                )

            logger.info(f"Emergency alert {alert_id} notifications sent successfully")
            return True

        except Exception as e:
            logger.error(f"Failed to send emergency notifications: {str(e)}")
            raise

    @staticmethod
    def _send_emergency_sms(
        phone_numbers: List[str],
        alert_id: str,
        alert_type: str,
        latitude: float,
        longitude: float,
    ):
        """
        Send SMS to emergency contacts
        Integrate with Twilio API for production
        """
        try:
            # TODO: Implement Twilio integration
            # from twilio.rest import Client
            # client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
            
            message = (
                f"🚨 EMERGENCY ALERT 🚨\n"
                f"Type: {alert_type.upper()}\n"
                f"Location: {latitude}, {longitude}\n"
                f"Alert ID: {alert_id}\n"
                f"Help requested. Check SafariSalama app for details."
            )

            for phone in phone_numbers:
                # For production, uncomment and use real Twilio:
                # client.messages.create(
                #     body=message,
                #     from_=TWILIO_PHONE_NUMBER,
                #     to=phone
                # )
                logger.info(f"SMS sent to {phone}: {alert_type} alert")

        except Exception as e:
            logger.error(f"SMS notification failed: {str(e)}")
            raise

    @staticmethod
    def _send_driver_push_notification(
        driver_ids: List[str],
        alert_id: str,
        alert_type: str,
        user_id: str,
        latitude: float,
        longitude: float,
    ):
        """
        Send push notification to nearby drivers
        Integrate with Firebase Cloud Messaging (FCM) for production
        """
        try:
            # TODO: Implement FCM integration
            # import firebase_admin
            # from firebase_admin import messaging
            
            notification_data = {
                "title": f"Emergency: {alert_type.upper()}",
                "body": "A nearby passenger needs help. Tap to view location.",
                "alert_id": alert_id,
                "user_id": user_id,
                "latitude": str(latitude),
                "longitude": str(longitude),
                "alert_type": alert_type,
            }

            for driver_id in driver_ids:
                # For production, get driver's FCM token and send:
                # message = messaging.Message(
                #     notification=messaging.Notification(
                #         title=notification_data["title"],
                #         body=notification_data["body"],
                #     ),
                #     data=notification_data,
                #     token=driver_fcm_token,
                # )
                # messaging.send(message)
                logger.info(f"Push notification sent to driver {driver_id}: {alert_type} alert")

        except Exception as e:
            logger.error(f"Push notification failed: {str(e)}")
            raise

    @staticmethod
    def _send_admin_notification(
        admin_id: str,
        alert_id: str,
        alert_type: str,
        user_id: str,
    ):
        """
        Send notification to SACCO admin
        Can be in-app, email, or SMS
        """
        try:
            # TODO: Implement admin notification (email or in-app)
            # Send email to admin
            # from sendgrid import SendGridAPIClient
            # from sendgrid.helpers.mail import Mail
            
            subject = f"Emergency Alert: {alert_type.upper()}"
            body = (
                f"User {user_id} triggered an emergency alert.\n"
                f"Alert Type: {alert_type}\n"
                f"Alert ID: {alert_id}\n"
                f"Check the admin panel for location and details."
            )

            # For production:
            # sg = SendGridAPIClient(SENDGRID_API_KEY)
            # message = Mail(
            #     from_email=ADMIN_FROM_EMAIL,
            #     to_emails=admin_email,
            #     subject=subject,
            #     plain_text_content=body,
            # )
            # sg.send(message)

            logger.info(f"Admin notification sent for alert {alert_id}")

        except Exception as e:
            logger.error(f"Admin notification failed: {str(e)}")
            raise

    @staticmethod
    def send_trip_notification(
        driver_id: str,
        passenger_name: str,
        pickup_location: str,
        vehicle_registration: str,
    ):
        """
        Send trip confirmation to driver
        """
        try:
            message = (
                f"New trip request from {passenger_name}\n"
                f"Pickup: {pickup_location}\n"
                f"Vehicle: {vehicle_registration}\n"
                f"Tap to accept or decline."
            )

            logger.info(f"Trip notification sent to driver {driver_id}")
            # Integrate with FCM for production

        except Exception as e:
            logger.error(f"Trip notification failed: {str(e)}")
            raise

    @staticmethod
    def send_trip_started_notification(
        passenger_id: str,
        driver_name: str,
        driver_phone: str,
        vehicle_registration: str,
    ):
        """
        Notify passenger that trip has started
        """
        try:
            message = (
                f"Trip started with {driver_name}\n"
                f"Driver: {driver_phone}\n"
                f"Vehicle: {vehicle_registration}\n"
                f"Your journey is being tracked for safety."
            )

            logger.info(f"Trip started notification sent to passenger {passenger_id}")
            # Integrate with FCM for production

        except Exception as e:
            logger.error(f"Trip started notification failed: {str(e)}")
            raise

    @staticmethod
    def send_trip_completed_notification(
        passenger_id: str,
        trip_id: str,
        fare_amount: float,
        distance_km: float,
    ):
        """
        Send trip completion summary to passenger
        """
        try:
            message = (
                f"Trip completed!\n"
                f"Distance: {distance_km:.1f} km\n"
                f"Fare: KES {fare_amount:.2f}\n"
                f"Thank you for using SafariSalama!"
            )

            logger.info(f"Trip completed notification sent to passenger {passenger_id}")
            # Integrate with FCM for production

        except Exception as e:
            logger.error(f"Trip completion notification failed: {str(e)}")
            raise
