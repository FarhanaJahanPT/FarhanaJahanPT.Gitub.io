{
    'name': 'Beyond Worksheet',
    'category': 'Project',
    'version': '17.0.1.0.0',
    'author': """""",
    'website': """""",
    'summary': '',
    'description': """""",
    'depends': ['base','project', 'web', 'sale_project'],
    'data': [
        'security/ir.model.access.csv',
        'views/project_task_view.xml',
        # 'views/worksheet_attendance_view.xml',
        'views/stock_lot_view.xml',
        'views/installation_checklist_view.xml',
        'views/installation_checklist_item_view.xml',
        'views/mail_message_view.xml',
        'views/owner_signature_templates.xml',
    ],
    'assets': {
        'web.assets_backend': [
           'beyond_worksheet/static/src/widgets/checklist_widget.js',
            'beyond_worksheet/static/src/widgets/checklist_widget.xml'
        ],
    },
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'OPL-1',
}
