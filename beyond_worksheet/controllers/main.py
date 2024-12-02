# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from datetime import datetime,timedelta
from odoo import fields,SUPERUSER_ID
from math import radians, sin, cos, sqrt, atan2


class OwnerSignature(http.Controller):

    @http.route('/my/task/<int:task_id>/signature', type="http", auth="public", website=True,
                sitemap=False)
    def owner_signature_forms(self, task_id, **kw):
        task = request.env['project.task'].sudo().browse(int(task_id))
        if not task.exists():
            return http.request.not_found()
        return request.render("beyond_worksheet.owner_signature_template",
                              {'task': task, })

    @http.route('/my/worksheet/<int:worksheet_id>', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_portal(self, worksheet_id, **kw):
        print("workseet portal",worksheet_id)
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})

    @http.route('/check/member', type='json', auth='public', methods=['POST'])
    def check_member(self, member_id):
        member = request.env['team.member'].sudo().search([('member_id', '=', member_id)], limit=1)
        return {'exists': bool(member), 'member_id': member.id}

    # @http.route('/worksheet/members/checkin/<int:user_id>/<int:worksheet_id>', type="http", auth="public", website=True,
    #             sitemap=False)
    # def worksheet_members_check_in(self, user_id, worksheet_id, **kw):
    #     request.env['worksheet.attendance'].sudo().create({
    #         'type': 'check_in',
    #         'user_id': user_id,
    #         'worksheet_id': worksheet_id
    #     })
    #     return request.redirect('/my/questions')

    @http.route('/my/task/<int:task_id>/signature/check', type='json',
                website=True)
    def task_signature_check(self, task_id, name=None, signature=None, **kwargs):
        task = request.env['project.task'].sudo().browse(task_id)
        if not task.exists():
            return http.request.not_found()
        task.customer_name = name
        task.customer_signature = signature
        task.date_worksheet_client_signature = datetime.now()
        return {
            'force_refresh': True,
        }

    # @http.route('/check/member/location', type='json', auth='user')
    # def check_member_location(self, member_id, latitude, longitude):
    #     # Calculate a small tolerance for location (e.g., 0.01 degrees is roughly 1.1 km)
    #     tolerance = 0.01
    #
    #     # Get today's date
    #     today = fields.Date.today()
    #
    #     # Search for existing attendance records
    #     existing_attendance = request.env['worksheet.attendance'].sudo().search([
    #         ('member_id', '=', member_id),
    #         ('date', '>=', today),
    #         ('date', '<', today + timedelta(days=1)),
    #         ('in_latitude', '>=', latitude - tolerance),
    #         ('in_latitude', '<=', latitude + tolerance),
    #         ('in_longitude', '>=', longitude - tolerance),
    #         ('in_longitude', '<=', longitude + tolerance)
    #     ])
    #     print(existing_attendance,"existance")
    #     return {
    #         'location_exists': bool(existing_attendance)
    #     }

    def haversine(self,lat1, lon1, lat2, lon2):

        R = 6371000  # Earth's radius in meters
        phi1, phi2 = radians(lat1), radians(lat2)
        delta_phi = radians(lat2 - lat1)
        delta_lambda = radians(lon2 - lon1)

        a = sin(delta_phi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(delta_lambda / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        print(R * c, "r c haversine")
        return R * c

    @http.route('/worksheet/values', type='json', auth='public', website=True, csrf=False)
    def survey_submit(self, **post):
        survey_id = post.get('survey_id')
        survey = request.env['survey.survey'].sudo().browse(int(survey_id))
        if survey.is_from_worksheet:
            today = datetime.today().date()
            latest_input = survey.user_input_ids.sudo().sorted(key=lambda r: r.create_date, reverse=True)[:1]
            attendance_record = request.env['worksheet.attendance'].sudo().search([
                ('survey_id', '=', survey.id),
                ('member_id', '=', survey.team_member_id.id),
                ('create_date', '>=', str(today) + ' 00:00:00'),
                ('create_date', '<=', str(today) + ' 23:59:59')
            ], limit=1)
            print(attendance_record,"att rec in submit")
            attendance_record.sudo().write({'user_input_id':latest_input.id})

    @http.route(['/my/questions/<int:worksheet>/<int:member>'], type='http',
                auth="public", website=True)
    def show_question(self, worksheet, member,latitude,longitude, **kwargs):
        # Fetch unanswered questions first
        member_id = kwargs.get('member_id') if kwargs.get('member_id') else member
        worksheet_id = kwargs.get('worksheet_id') if kwargs.get('worksheet_id') else worksheet
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        member = request.env['team.member'].sudo().browse(int(member_id))
        today = datetime.today().date()
        questions = request.env['survey.question'].sudo().search([('is_from_worksheet_questions', '=', True)])
        survey = request.env['survey.survey'].sudo().search([('team_member_id', '=', int(member_id)),
                                                             ('worksheet_id','=',int(worksheet_id)),
                                                             ('create_date', '>=', str(today) + ' 00:00:00'),
                                                             ('create_date', '<=', str(today) + ' 23:59:59')])
        if survey:
            if survey.answer_done_count >= 1 :
                return request.render('beyond_worksheet.portal_team_member_questions_done',{'worksheet': worksheet_id, 'member': member_id})
        # Create the survey and add questions to question_ids
        else:
            print("not seurvey not check in",type(member_id))
            existing_records = request.env['worksheet.attendance'].sudo().search([
                ('member_id', '=', int(member_id)),
                ('type', '=', 'check_in'),
                ('create_date', '>=', str(today) + ' 00:00:00'),
                ('create_date', '<=', str(today) + ' 23:59:59')
            ])
            print(existing_records, "existing record")
            for record in existing_records:
                distance = self.haversine(latitude, longitude, record.in_latitude, record.in_longitude)
                if distance <= 50:  # Threshold in meters
                    print("Check-in at the same location already exists")
                    return request.render('beyond_worksheet.portal_team_member_questions_done',
                                          {'worksheet': worksheet_id, 'member': member_id,'is_same_location': True})

            survey = request.env['survey.survey'].with_user(SUPERUSER_ID).create({
                'title': worksheet.name +'-'+ member.name +'-'+ str(datetime.today().date()),
                'user_id': request.env.user.id,
                'access_mode': 'public',
                'worksheet_id':worksheet_id,
                'team_member_id': member_id,
                'is_from_worksheet': True,
                'question_and_page_ids': [fields.Command.create({
                    'title': question.title,
                    'question_type': question.question_type,
                    'id': question.id,
                    'suggested_answer_ids': [fields.Command.create({
                        'value': answer.value if answer.value else False,
                        'value_image': answer.value_image if answer.value_image else False,

                    }) for answer in question.suggested_answer_ids],
                'answer_numerical_box': question.answer_numerical_box if question.answer_numerical_box else False,
                'answer_date': question.answer_date if question.answer_date else False,
                'answer_datetime': question.answer_datetime if question.answer_datetime else False,
                'is_scored_question': question.is_scored_question if question.is_scored_question else False,
                'description': question.description if question.description else False,
                    'matrix_row_ids': [fields.Command.create({
                        'value': answer.value if answer.value else False,
                    }) for answer in question.matrix_row_ids],
                'constr_mandatory': question.constr_mandatory if question.constr_mandatory else False,
                'constr_error_msg': question.constr_error_msg if question.constr_error_msg else False
                }) for question in questions]  # Add questions here
            })
            att = request.env['worksheet.attendance'].sudo().create({
                'type': 'check_in',
                'member_id': member_id,
                'worksheet_id': worksheet_id,
                'in_latitude': latitude,
                'in_longitude': longitude,
                'survey_id': survey.id,
            })
            print("vatt",att)
        print(survey,"========survey")
        print(survey.survey_start_url,"urlllllll")
        return request.redirect(survey.survey_start_url)


    # @http.route(['/my/questions/answer'], type='http', auth="public", website=True)
    # def submit_answer(self, **kwargs):
    #     worksheet = int(kwargs.get('worksheet_id'))
    #     member = int(kwargs.get('member_id'))
    #     # Get question and answer from the POST data
    #     request.env['worksheet.member.question'].sudo().create({
    #         'question_id': int(kwargs.get('question_id')),
    #         'answer': kwargs.get('answer'),
    #         'worksheet_id': worksheet,
    #         'member_id': member,
    #         'date': fields.Datetime.today()
    #     })
    #     # Redirect to the next question or finish if no more questions
    #     return request.redirect(
    #         '/my/questions/%s/%s/%s/%s' % (worksheet, member, kwargs.get('latitude'), kwargs.get('longitude')))

    @http.route('/team/member/checkout/<int:worksheet_id>/<int:member_id>', type='http', auth="public", website=True)
    def member_checkout(self, worksheet_id, member_id, **kwargs):
        # Implement any checkout logic here (e.g., marking the member as checked out).
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})
