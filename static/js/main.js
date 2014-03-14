    jQuery(document).ready(function() {
            // For now, topic selection is done manually via a text box
            jQuery(".button").click(function() {
                input_string = $$("input#textfield").val();
                off=0;
                jQuery('#values').html('Awaiting first value in stream, may take up to 10 seconds...');
                update();
                return false;
            });
        });