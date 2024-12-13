/** @odoo-module **/

import SurveyFormWidget from '@survey/js/survey_form';
console.log(SurveyFormWidget,"SurveyFormWidget")
SurveyFormWidget.include({
    _submitForm: async function (options) {
        var params = {};
        if (options.previousPageId) {
            params.previous_page_id = options.previousPageId;
        }
        if (options.nextSkipped) {
            params.next_skipped_page_or_question = true;
        }
        var route = "/survey/submit";

        if (this.options.isStartScreen) {
            route = "/survey/begin";
            // Hide survey title in 'page_per_question' layout: it takes too much space
            if (this.options.questionsLayout === 'page_per_question') {
                this.$('.o_survey_main_title').fadeOut(400);
            }
        } else {
            var $form = this.$('form');
            console.log($form,"$form")
            var formData = new FormData($form[0]);
            console.log(formData,"formData")
            if (!options.skipValidation) {
                // Validation pre submit
                if (!this._validateForm($form, formData)) {
                    return;
                }
            }
            this._prepareSubmitValues(formData, params);

        }

        // prevent user from submitting more times using enter key
        this.preventEnterSubmit = true;

        if (this.options.sessionInProgress) {
            // reset the fadeInOutDelay when attendee is submitting form
            this.fadeInOutDelay = 400;
            // prevent user from clicking on matrix options when form is submitted
            this.readonly = true;
        }
        if (options.isFinish){
                params.survey_id = $form[0].name
                console.log($form[0].name,"idddddddddddd")
                  this.rpc("/worksheet/values",params
                                ).then(function(result) {
                                console.log("elseeee")
                            })
//                var self = this
//                if ("geolocation" in navigator) {
//                    console.log('geooooo09999999999')
//                    navigator.geolocation.getCurrentPosition(
//                        (position) => {
//                            console.log('geooooo',position)
//                            params.latitude = position.coords.latitude
//                            params.longitude = position.coords.longitude
//                            this.rpc("/worksheet/values",params
//                                ).then(function(result) {
//                                console.log("ifff")
//                            })
//                        },
//                        (error) => {
//                            console.error("Error retrieving location:", error);
//                        }
//                    );
//                }
//                else{
//                    console.log("else workhseet")
//                     this.rpc("/worksheet/values",params
//                                ).then(function(result) {
//                                console.log("elseeee")
//                            })
//                }
        }
        const submitPromise = this.rpc(
            `${route}/${this.options.surveyToken}/${this.options.answerToken}`,
            params
        );

        if (!this.options.isStartScreen && this.options.scoringType == 'scoring_with_answers_after_page') {
            const [correctAnswers] = await submitPromise;
            if (Object.keys(correctAnswers).length && document.querySelector('.js_question-wrapper')) {
                this._showCorrectAnswers(correctAnswers, submitPromise, options);
                return;
            }
        }
        this._nextScreen(submitPromise, options);
//        window.location.reload()
    },
        _onNextScreenDone: function (options) {
        var self = this;
        var result = this.nextScreenResult;

        if ((!(options && options.isFinish) || result.has_skipped_questions)
            && !this.options.sessionInProgress) {
            this.preventEnterSubmit = false;
        }

        if (result && !result.error) {
            this.$(".o_survey_form_content").empty();
            this.$(".o_survey_form_content").html(result.survey_content);

            if (result.survey_progress && this.$surveyProgress.length !== 0) {
                this.$surveyProgress.html(result.survey_progress);
            } else if (options.isFinish && this.$surveyProgress.length !== 0) {
                this.$surveyProgress.remove();
            }

            if (result.survey_navigation && this.$surveyNavigation.length !== 0) {
                this.$surveyNavigation.html(result.survey_navigation);
                this.$surveyNavigation.find('.o_survey_navigation_submit').on('click', self._onSubmit.bind(self));
            }

            // Hide timer if end screen (if page_per_question in case of conditional questions)
            if (self.options.questionsLayout === 'page_per_question' && this.$('.o_survey_finished').length > 0) {
                options.isFinish = true;
            }

            // Start datetime pickers
            self.trigger_up("widgets_start_request", { $target: this.$el.find('.o_survey_form_date') });
            if (this.options.isStartScreen || (options && options.initTimer)) {
                this._initTimer();
                this.options.isStartScreen = false;
            } else {
                if (this.options.sessionInProgress && this.surveyTimerWidget) {
                    this.surveyTimerWidget.destroy();
                }
            }
            if (options && options.isFinish && !result.has_skipped_questions) {
                this._initResultWidget();
                if (this.surveyBreadcrumbWidget) {
                    this.$('.o_survey_breadcrumb_container').addClass('d-none');
                    this.surveyBreadcrumbWidget.destroy();
                }
                if (this.surveyTimerWidget) {
                    this.surveyTimerWidget.destroy();
                }
            } else {
                this._updateBreadcrumb();
            }
            self._initChoiceItems();
            self._initTextArea();

            if (this.options.sessionInProgress && this.$('.o_survey_form_content_data').data('isPageDescription')) {
                // prevent enter submit if we're on a page description (there is nothing to submit)
                this.preventEnterSubmit = true;
            }
            // Background management - reset background overlay opacity to 0.7 to discover next background.
            if (this.options.refreshBackground) {
                $('div.o_survey_background').css("background-image", "url(" + result.background_image_url + ")");
                $('div.o_survey_background').removeClass('o_survey_background_transition');
            }
            this.$('.o_survey_form_content').fadeIn(this.fadeInOutDelay);
            $("html, body").animate({ scrollTop: 0 }, this.fadeInOutDelay);

            this.$('button[type="submit"]').removeClass('disabled');

            this._scrollToFirstError();
            self._focusOnFirstInput();
        } else if (result && result.fields && result.error === 'validation') {
            this.$('.o_survey_form_content').fadeIn(0);
            this._showErrors(result.fields);
        } else {
            var $errorTarget = this.$('.o_survey_error');
            $errorTarget.removeClass("d-none");
            this._scrollToError($errorTarget);
        }
        if (options.isFinish){
            window.location.reload()
        }
    },
});
