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
                                  {'task': task,})

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

    @http.route(['/my/questions/<int:worksheet>/<int:member>/<float:latitude>/<float:longitude>'], type='http',
                auth="public", website=True)
    def show_question(self, worksheet, member, latitude, longitude, **kwargs):
        # Fetch unanswered questions first
        member_id = kwargs.get('member_id') if kwargs.get('member_id') else member
        worksheet_id = kwargs.get('worksheet_id') if kwargs.get('worksheet_id') else worksheet
        worksheet = request.env['task.worksheet'].sudo().browse(int(worksheet_id))
        check_in = worksheet.worksheet_attendance_ids.filtered(
            lambda a: a.date.date() == fields.datetime.today().date() and a.member_id.id == int(
                member_id) and a.type == 'check_in')
        if check_in:
            return request.render('beyond_worksheet.portal_team_member_questions_done',
                                  {'worksheet': worksheet_id, 'member': member_id})
        questions = worksheet.member_question_ids.filtered(
            lambda q: q.date.date() == fields.datetime.today().date() and q.member_id.id == int(member_id)).mapped(
            'question_id')
        if questions and not check_in:
            questions = request.env['team.member.question'].sudo().search([('id', 'not in', questions.ids)], limit=1)
        elif not questions and not check_in:
            questions = request.env['team.member.question'].sudo().search([], limit=1)

        if not questions and not check_in:
            request.env['worksheet.attendance'].sudo().create({
                'type': 'check_in',
                'member_id': member_id,
                'worksheet_id': worksheet_id,
                'in_latitude': latitude,
                'in_longitude': longitude
            })
            # If all questions are answered, redirect to a thank you page
            return request.render('beyond_worksheet.portal_team_member_questions_done')
        # Show the next unanswered question
        return request.render('beyond_worksheet.portal_team_member_question', {
            'question': questions[0], 'worksheet': worksheet_id, 'member': member_id, 'latitude': latitude,
            'longitude': longitude
        })

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
        # Optionally, you can retrieve and update data for the specific member.
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
                'worksheet_id': worksheet_id
            })
        # Render the checkout template
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'worksheet': worksheet_id})
