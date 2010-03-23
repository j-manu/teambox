Event.addBehavior({
  ".google_docs_input:click": function(e){
      top.$('google_docs_list').innerHTML = '';
      $('google_docs_attach').select('input[type="checkbox"]').each(function(ele){
        if( $(ele).checked ){
          top.$('google_docs_list').insert($(ele).cloneNode(true));
        }
      });
    }
});
