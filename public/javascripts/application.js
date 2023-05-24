$(function() {


  $('form.delete').submit(function(event) { //whenever the form is submitted, it will call this function
    event.preventDefault(); //prevent the default event from occuring
    event.stopPropagation(); //prevent the event from being interpreted by another part of the page, or the browser itself

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      // this.submit();

      var form = $(this);

      var request = $.ajax({ // $ is the jquery object; equivalent to jQuery()
        url: form.attr('action'),
        method: form.attr('method')
      });  

      request.done(function(data, textStatus, jqXHR) { // #done only executes if the request is successful. #fail handles the failure case, good practice to use in general
        if (jqXHR.status === 204) {// == will try to convert the two values being compared to a similar type, while === directly compares those values without the attempt at conversion. (not the same as in Ruby)
          form.parent("li").remove(); 
        } else if (jqXHR.status === 200) {
          document.location = data; // browser is sent to the path provided by the return value of the route
        };

      });

    }
  });

});
