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
    },
});
