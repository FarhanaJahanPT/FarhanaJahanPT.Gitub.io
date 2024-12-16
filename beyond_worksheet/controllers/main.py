# -*- coding: utf-8 -*-
from dateutil.utils import today

from odoo import http
from odoo.http import request
from datetime import datetime, timedelta
from odoo import fields, SUPERUSER_ID
from math import radians, sin, cos, sqrt, atan2


class OwnerSignature(http.Controller):

    # Function for checking same location login
    def haversine(self, lat1, lon1, lat2, lon2):
        """ Comparing location """
        R = 6371000  # Earth's radius in meters
        phi1, phi2 = radians(lat1), radians(lat2)
        delta_phi = radians(lat2 - lat1)
        delta_lambda = radians(lon2 - lon1)
        a = sin(delta_phi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(delta_lambda / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c

    @http.route('/my/task/<int:task_id>/signature', type="http", auth="public", website=True,
                sitemap=False)
    def owner_signature_forms(self, task_id, **kw):
        task = request.env['project.task'].sudo().browse(int(task_id))
        if not task.exists():
            return http.request.not_found()
        return request.render("beyond_worksheet.owner_signature_template",
                              {'task': task, })

    @http.route('/my/task/<int:task_id>/signature/check', type='json',
                website=True)
    def task_signature_check(self, task_id, name=None, signature=None, **kwargs):
        task = request.env['project.task'].sudo().browse(task_id)
        if not task.exists():
            return http.request.not_found()
        task.customer_name = name
        task.customer_signature = signature
        task.date_worksheet_client_signature = datetime.now()
        return ({
            'force_refresh': True,
        })

    # Team member signature
    @http.route('/my/worksheet/<int:worksheet_id>/<int:survey_id>/signature/check', type='json',
                website=True)
    def member_signature_check(self, worksheet_id, survey_id, name=None, signature=None, **kwargs):
        survey = request.env['survey.survey'].sudo().browse(survey_id)
        survey.signature = signature
        return {
            'force_refresh': True,
            'is_worksheet':True,
            'worksheet_id':worksheet_id,
            'member_id':survey.team_member_id.id,
            'survey_id':survey.id
        }
    # Team member worksheet start
    @http.route('/my/worksheet/<int:worksheet_id>', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_portal(self, worksheet_id, **kw):
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})

    # Checking member with member id
    @http.route('/check/member', type='json', auth='public', methods=['POST'])
    def check_member(self, member_id, worksheet_id):
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        # Check if the member is a team member or the team lead
        is_team_member = worksheet.team_member_ids.filtered(lambda l: l.member_id == member_id)
        is_team_lead = worksheet.team_lead_id and worksheet.team_lead_id.member_id == member_id
        # Prepare the response
        if is_team_member:
            return {'exists': True, 'member_id': is_team_member.id}
        elif is_team_lead:
            return {'exists': True, 'member_id': worksheet.team_lead_id.id}
        return {'exists': False, 'member_id': None}

    @http.route(['/my/swms/report/<int:worksheet>/<int:member>'], type='http', auth="public", website=True)
    def show_swms_report(self, worksheet, member, **kwargs):
        """Displays the SWMS report for a member and worksheet."""
        worksheet = request.env['task.worksheet'].sudo().browse(worksheet)
        today = fields.Date.today()

        # Filter today's check-in and check-out records
        attendance_today = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == today and a.member_id.id == member
        )
        check_in = attendance_today.filtered(lambda a: a.type == 'check_in')
        check_out = attendance_today.filtered(lambda a: a.type == 'check_out')
        # Handle scenarios for check-in and check-out
        if check_in and not check_out:
            return request.render('beyond_worksheet.portal_team_member_checkin_completed', {
                'worksheet': worksheet.id,
                'member': member,
                'is_same_location': False
            })
        if check_in and check_out:
            return request.render("beyond_worksheet.portal_team_member_checkout",{'worksheet':worksheet})
        # Retrieve SWMS data based on product categories in the sale order
        worksheet.action_create_swms()
        # Render the SWMS report
        return request.render("beyond_worksheet.swms_repoart", {
            'worksheet': worksheet,
            'member': member,
        })

    @http.route(['/my/questions/<int:worksheet>/<int:member>'], type='http', auth="public", website=True)
    def show_question(self, worksheet, member, **kwargs):
        """Displays or creates a survey with installation questions for the specified worksheet and team member."""
        today = fields.Date.today()

        # Ensure worksheet_id and member_id are integers
        worksheet_id = int(kwargs.get('worksheet_id', worksheet))
        member_id = int(kwargs.get('member_id', member))

        worksheet = request.env['task.worksheet'].sudo().browse(worksheet_id)
        member = request.env['team.member'].sudo().browse(member_id)
        survey_model = request.env['survey.survey'].sudo()
        attendance_model = request.env['worksheet.attendance'].sudo()
        question_model = request.env['survey.question'].sudo()

        # Check for an existing survey for the member and worksheet on the same day
        survey = survey_model.search([
            ('team_member_id', '=', member_id),
            ('worksheet_id', '=', worksheet_id),
            ('create_date', '>=', f"{today} 00:00:00"),
            ('create_date', '<=', f"{today} 23:59:59")
        ], limit=1)

        if survey:
            # Check if the member has already checked in and answered questions
            existing_attendance = attendance_model.search([
                ('member_id', '=', member_id),
                ('type', '=', 'check_in'),
                ('worksheet_id', '=', worksheet_id),
                ('create_date', '>=', f"{today} 00:00:00"),
                ('create_date', '<=', f"{today} 23:59:59")
            ], limit=1)

            if survey.answer_done_count >= 1 and existing_attendance:
                return request.render('beyond_worksheet.portal_team_member_checkin_completed', {
                    'worksheet': worksheet_id,
                    'member': member_id
                })

        else:
            # Create a new survey and add questions
            questions = question_model.search([('is_from_worksheet_questions', '=', True)])
            survey = request.env['survey.survey'].with_user(SUPERUSER_ID).create({
                'title': f"{worksheet.name}-{member.name}-{today}",
                'user_id': request.env.user.id,
                'access_mode': 'public',
                'worksheet_id': worksheet_id,
                'team_member_id': member_id,
                'is_from_worksheet': True,
                'question_and_page_ids': [
                    fields.Command.create({
                        'title': question.title,
                        'question_type': question.question_type,
                        'suggested_answer_ids': [
                            fields.Command.create({
                                'value': answer.value,
                                'value_image': answer.value_image,
                            }) for answer in question.suggested_answer_ids
                        ],
                        'answer_numerical_box': question.answer_numerical_box,
                        'answer_date': question.answer_date,
                        'answer_datetime': question.answer_datetime,
                        'is_scored_question': question.is_scored_question,
                        'description': question.description,
                        'matrix_row_ids': [
                            fields.Command.create({'value': row.value}) for row in question.matrix_row_ids
                        ],
                        'constr_mandatory': question.constr_mandatory,
                        'constr_error_msg': question.constr_error_msg
                    }) for question in questions
                ]
            })

        # Redirect to the survey start URL
        return request.redirect(survey.survey_start_url)

    # Checkin record creation
    @http.route(
        '/team/member/checkin/<int:survey_id>/<int:worksheet_id>/<int:member_id>/<float:latitude>/<float:longitude>',
        type="http", auth="public", website=True, sitemap=False)
    def worksheet_members_check_in(self, survey_id, worksheet_id, member_id, latitude, longitude, **kw):
        Survey = request.env['survey.survey'].sudo()
        Attendance = request.env['worksheet.attendance'].sudo()
        today = datetime.today().date()

        # Fetch survey and the latest input
        survey = Survey.browse(survey_id)
        latest_input = survey.user_input_ids.sorted(key=lambda r: r.create_date, reverse=True)[:1]

        # Check for existing check-ins today
        existing_attendance = Attendance.search([
            ('member_id', '=', member_id),
            ('type', '=', 'check_in'),
            ('create_date', '>=', f"{today} 00:00:00"),
            ('create_date', '<=', f"{today} 23:59:59")
        ])

        if existing_attendance:
            for record in existing_attendance:
                distance = self.haversine(latitude, longitude, record.in_latitude, record.in_longitude)
                if distance <= 200:  # Threshold in meters
                    return request.render('beyond_worksheet.portal_team_member_checkin_completed', {
                        'worksheet': worksheet_id,
                        'member': member_id,
                        'is_same_location': True
                    })

            # Check-in exists but not at the same location
            return request.render('beyond_worksheet.portal_team_member_checkin_completed', {
                'worksheet': worksheet_id,
                'member': member_id,
                'is_same_location': False
            })

        # Create a new check-in record
        check_in = Attendance.create({
            'type': 'check_in',
            'member_id': member_id,
            'worksheet_id': worksheet_id,
            'in_latitude': latitude,
            'in_longitude': longitude,
            'survey_id': survey_id,
            'signature': survey.signature,
            'user_input_id': latest_input.id if latest_input else None,
            'date': today
        })
        return request.render('beyond_worksheet.portal_team_member_checkin_completed', {
            'worksheet': worksheet_id,
            'member': member_id,
            'is_same_location': False
        })

    @http.route('/team/member/checkout/<int:worksheet_id>/<int:member_id>', type='http', auth="public", website=True)
    def member_checkout(self, worksheet_id, member_id, **kwargs):
        """Handles the member checkout process."""
        today = fields.Date.today()
        worksheet = request.env['task.worksheet'].sudo().browse(worksheet_id)

        # Filter attendance records for today's check-in and check-out
        attendance_today = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == today and a.member_id.id == member_id
        )
        check_in = attendance_today.filtered(lambda a: a.type == 'check_in')
        check_out = attendance_today.filtered(lambda a: a.type == 'check_out')

        # Create check-out record if a check-in exists without a corresponding check-out
        if check_in and not check_out:
            request.env['worksheet.attendance'].sudo().create({
                'type': 'check_out',
                'member_id': member_id,
                'worksheet_id': worksheet_id,
                'date': today
            })

        # Render the checkout template
        return request.render("beyond_worksheet.portal_team_member_checkout",{'worksheet':worksheet})

    @http.route('/worksheet/additional/risk',  type='json', auth='public')
    def additional_risk(self,worksheet_id,risk):
        request.env['additional.risk'].sudo().create({
            'name': risk,
            'worksheet_id': worksheet_id,
        })