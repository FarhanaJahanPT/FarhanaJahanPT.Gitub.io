# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from datetime import datetime
from odoo import fields


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
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})

    @http.route('/check/member', type='json', auth='public', methods=['POST'])
    def check_member(self, member_id):
        member = request.env['team.member'].sudo().search([('member_id', '=', member_id)], limit=1)
        return {'exists': bool(member), 'member_id': member.id}

    @http.route('/worksheet/members/checkin/<int:user_id>/<int:worksheet_id>', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_check_in(self, user_id, worksheet_id, **kw):
        request.env['worksheet.attendance'].sudo().create({
            'type': 'check_in',
            'user_id': user_id,
            'worksheet_id': worksheet_id
        })
        return request.redirect('/my/questions')

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


    @http.route('/worksheet/values', type='json', auth='public', website=True, csrf=False)
    def survey_submit(self, **post):
        survey_id = post.get('survey_id')
        survey = request.env['survey.survey'].sudo().browse(int(survey_id))
        if survey.is_from_worksheet:
            latest_input = survey.user_input_ids.sudo().sorted(key=lambda r: r.create_date, reverse=True)[:1]
            request.env['worksheet.attendance'].sudo().create({
                'type': 'check_in',
                'member_id': survey.team_member_id.id,
                'worksheet_id': survey.worksheet_id.id,
                'survey_id': survey.id,
                'in_longitude':post.get('longitude') if post.get('longitude') else 0.00 ,
                'in_latitude':post.get('latitude') if post.get('latitude') else 0.00,
                'user_input_id': latest_input.id,
            })
        else:
            return False

    @http.route(['/my/questions/<int:worksheet>/<int:member>'], type='http',
                auth="public", website=True)
    def show_question(self, worksheet, member, **kwargs):
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
            if survey.answer_done_count >= 1:
                return request.render('beyond_worksheet.portal_team_member_questions_done',{'worksheet': worksheet_id, 'member': member_id})
        # Create the survey and add questions to question_ids
        elif not survey:
            survey = request.env['survey.survey'].sudo().create({
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
        survey_invite = request.env['survey.invite'].sudo().with_context({'allowed_company_ids': [1],
                                                                              'default_survey_id': survey.id,
                                                                              'default_email_layout_xmlid':
                                                                                  'mail.mail_notification_light',
                                                                              'default_send_email': False}).create({})
        return request.redirect(survey_invite.survey_start_url)


    @http.route(['/my/questions/answer'], type='http', auth="public", website=True)
    def submit_answer(self, **kwargs):
        worksheet = int(kwargs.get('worksheet_id'))
        member = int(kwargs.get('member_id'))
        # Get question and answer from the POST data
        request.env['worksheet.member.question'].sudo().create({
            'question_id': int(kwargs.get('question_id')),
            'answer': kwargs.get('answer'),
            'worksheet_id': worksheet,
            'member_id': member,
            'date': fields.Datetime.today()
        })
        # Redirect to the next question or finish if no more questions
        return request.redirect(
            '/my/questions/%s/%s/%s/%s' % (worksheet, member, kwargs.get('latitude'), kwargs.get('longitude')))

    @http.route('/team/member/checkout/<int:worksheet_id>/<int:member_id>', type='http', auth="public", website=True)
    def member_checkout(self, worksheet_id, member_id, **kwargs):
        # Implement any checkout logic here (e.g., marking the member as checked out).
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})
