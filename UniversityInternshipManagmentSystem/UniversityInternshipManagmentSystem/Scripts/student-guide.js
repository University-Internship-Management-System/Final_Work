(function(){
    'use strict';
    var preview=document.getElementById('guidePreview'),full=document.getElementById('guideFullVideo'),dialog=document.getElementById('studentGuideDialog'),open=document.getElementById('openStudentGuide'),close=document.getElementById('closeStudentGuide');
    if(!preview||!dialog)return;
    preview.muted=true;
    function play(video){var result=video.play();if(result&&result.catch)result.catch(function(){});}
    open.addEventListener('click',function(){
        preview.pause();dialog.showModal();document.body.classList.add('uims-guide-modal-open');
        full.currentTime=0;full.muted=false;full.volume=1;play(full);
    });
    close.addEventListener('click',function(){dialog.close();});
    dialog.addEventListener('click',function(event){if(event.target===dialog){var box=dialog.getBoundingClientRect();if(event.clientX<box.left||event.clientX>box.right||event.clientY<box.top||event.clientY>box.bottom)dialog.close();}});
    dialog.addEventListener('close',function(){full.pause();document.body.classList.remove('uims-guide-modal-open');preview.muted=true;play(preview);open.focus({preventScroll:true});});
    if('IntersectionObserver' in window){new IntersectionObserver(function(entries){if(entries[0].isIntersecting&&!dialog.open)play(preview);else preview.pause();},{threshold:.15}).observe(preview);}
})();
