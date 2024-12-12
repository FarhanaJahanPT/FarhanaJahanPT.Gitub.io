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
        print(R * c, "r c haversine")
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
    # Team member workhseet start
    @http.route('/my/worksheet/<int:worksheet_id>', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_portal(self, worksheet_id, **kw):
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})

    # Checking member with member id
    @http.route('/check/member', type='json', auth='public', methods=['POST'])
    def check_member(self, member_id, worksheet_id):
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        member = worksheet.team_member_ids.filtered(lambda l: l.member_id == member_id)
        print(member, "dddddddddd")
        return {'exists': bool(member), 'member_id': member.id if member else None}

    # Display swms summary
    @http.route(['/my/swms/report/<int:worksheet>/<int:member>'], type='http', auth="public",
                website=True)
    def show_swms_report(self, worksheet, member, **kwargs):
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet))
        check_in = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == fields.datetime.today().date() and a.member_id.id == int(
                member) and a.type == 'check_in')
        check_out = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == fields.datetime.today().date() and a.member_id.id == int(
                member) and a.type == 'check_out')
        if check_in and not check_out:
            return request.render('beyond_worksheet.portal_team_member_checkin_completed',
                                  {'worksheet': int(worksheet), 'member': int(member),
                                   'is_same_location': False})
        if check_in and check_out:
            return request.render("beyond_worksheet.portal_team_member_checkout")
        order_line_categ_ids = worksheet.sale_id.order_line.product_id.categ_id.mapped('id')
        print(order_line_categ_ids, "order_line_categ_ids")
        swms_data = request.env['swms.risk.register'].sudo().search([('category_id', 'in', order_line_categ_ids)])
        print(swms_data, "swms_report")
        return request.render("beyond_worksheet.swms_repoart",
                              {'worksheet': worksheet, 'member': member, 'swms_data': swms_data})

    # show installation question from the survey
    @http.route(['/my/questions/<int:worksheet>/<int:member>'], type='http',
                auth="public", website=True)
    def show_question(self, worksheet, member, **kwargs):
        print("show question")
        # Fetch unanswered questions first
        member_id = kwargs.get('member_id') if kwargs.get('member_id') else member
        worksheet_id = kwargs.get('worksheet_id') if kwargs.get('worksheet_id') else worksheet
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        member = request.env['team.member'].sudo().browse(int(member_id))
        today = datetime.today().date()
        questions = request.env['survey.question'].sudo().search([('is_from_worksheet_questions', '=', True)])
        print(questions, "qqqqqqqq")
        survey = request.env['survey.survey'].sudo().search([('team_member_id', '=', int(member_id)),
                                                             ('worksheet_id', '=', int(worksheet_id)),
                                                             ('create_date', '>=', str(today) + ' 00:00:00'),
                                                             ('create_date', '<=', str(today) + ' 23:59:59')])
        if survey:
            existing_record = request.env['worksheet.attendance'].sudo().search([
                ('member_id', '=', int(member_id)),
                ('type', '=', 'check_in'),
                ('worksheet_id', '=', int(worksheet_id)),
                ('create_date', '>=', str(today) + ' 00:00:00'),
                ('create_date', '<=', str(today) + ' 23:59:59')
            ])
            if survey.answer_done_count >= 1 and existing_record:
                return request.render('beyond_worksheet.portal_team_member_checkin_completed',
                                      {'worksheet': worksheet_id, 'member': member_id})
        # Create the survey and add questions to question_ids
        else:
            survey = request.env['survey.survey'].with_user(SUPERUSER_ID).create({
                'title': worksheet.name + '-' + member.name + '-' + str(datetime.today().date()),
                'user_id': request.env.user.id,
                'access_mode': 'public',
                'worksheet_id': worksheet_id,
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

        print(survey, "========survey")
        print(survey.survey_start_url, "urlllllll")
        return request.redirect(survey.survey_start_url)

    # Checkin record creation
    @http.route(
        '/team/member/checkin/<int:survey_id>/<int:worksheet_id>/<int:member_id>/<float:latitude>/<float:longitude>',
        type="http", auth="public",
        website=True,
        sitemap=False)
    def worksheet_members_check_in(self, survey_id, worksheet_id, member_id, latitude, longitude, **kw):
        survey = request.env['survey.survey'].sudo().browse(int(survey_id))
        latest_input = survey.user_input_ids.sudo().sorted(key=lambda r: r.create_date, reverse=True)[:1]
        today = datetime.today().date()
        existing_attendance = request.env['worksheet.attendance'].sudo().search([
            ('member_id', '=', int(member_id)),
            ('type', '=', 'check_in'),
            ('create_date', '>=', str(today) + ' 00:00:00'),
            ('create_date', '<=', str(today) + ' 23:59:59')
        ])
        if existing_attendance:
            if any(record.member_id.id == member_id for record in existing_attendance):
                print(existing_attendance, "if checkin existing record")
                return request.render('beyond_worksheet.portal_team_member_checkin_completed',
                                      {'worksheet': worksheet_id, 'member': member_id, 'is_same_location': False})
            else:
                for record in existing_attendance:
                    distance = self.haversine(latitude, longitude, record.in_latitude, record.in_longitude)
                    if distance <= 200:  # Threshold in meters
                        print("Check-in at the same location already exists")
                        return request.render('beyond_worksheet.portal_team_member_checkin_completed',
                                              {'worksheet': worksheet_id, 'member': member_id,
                                               'is_same_location': True})
        else:
            check_in = request.env['worksheet.attendance'].sudo().create({
                'type': 'check_in',
                'member_id': member_id,
                'worksheet_id': worksheet_id,
                'in_latitude': latitude,
                'in_longitude': longitude,
                'survey_id': survey_id,
                'signature': survey.signature,
                'user_input_id': latest_input.id,
                'date': today
            })
            print("check_in", check_in, worksheet_id, member_id)
            return request.render('beyond_worksheet.portal_team_member_checkin_completed',
                                  {'worksheet': int(worksheet_id), 'member': int(member_id),
                                   'is_same_location': False})
    # checkout record creation
    @http.route('/team/member/checkout/<int:worksheet_id>/<int:member_id>', type='http', auth="public", website=True)
    def member_checkout(self, worksheet_id, member_id, **kwargs):
        # Implement any checkout logic here (e.g., marking the member as checked out).
        # Optionally, you can retrieve and update data for the specific member.
        print('++++', kwargs)
        today = fields.Date.today()
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        check_in = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == fields.datetime.today().date() and a.member_id.id == int(
                member_id) and a.type == 'check_in')
        check_out = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == fields.datetime.today().date() and a.member_id.id == int(
                member_id) and a.type == 'check_out')
        if check_in and not check_out:
            request.env['worksheet.attendance'].sudo().create({
                'type': 'check_out',
                'member_id': member_id,
                'worksheet_id': worksheet_id,
                'date': today
            })
        # Render the checkout template
        return request.render("beyond_worksheet.portal_team_member_checkout",)

    # @http.route('/my/worksheet/<int:worksheet_id>/<int:survey_id>/signature/status', type='json', auth='user')
    # def check_signature_status(self, worksheet_id, survey_id):
    #     attendance = request.env['survey.survey'].sudo().search([
    #         ('worksheet_id', '=', worksheet_id),
    #         ('id', '=', survey_id),
    #         ('is_from_worksheet', '=', True),
    #         ('signature', '!=', False),
    #     ], limit=1)
    #     print(attendance, "a attendance aaaaaaa")
    #     return {'signature_completed': bool(attendance)}