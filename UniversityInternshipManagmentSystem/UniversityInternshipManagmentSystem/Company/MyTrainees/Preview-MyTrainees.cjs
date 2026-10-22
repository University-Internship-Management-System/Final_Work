'use strict';
// Standalone fixture renderer, NOT a Web Forms route, login, or Firebase service.
const fs = require('fs');
const path = require('path');
const http = require('http');
const {spawnSync} = require('child_process');
const assert = require('assert');
const folder = __dirname;
const app = path.resolve(folder, '../..');
const args = process.argv.slice(2);
if (require.main !== module) throw new Error('Run this preview explicitly from the command line only.');
if (Object.keys(process.env).some(k => /^(NODE_ENV|ASPNET_ENVIRONMENT|DOTNET_ENVIRONMENT)$/i.test(k) && /^production$/i.test(process.env[k])) || process.env.APP_POOL_ID || process.env.APPL_PHYSICAL_PATH) {
    console.error('Refused: this tool cannot run in a production environment or IIS application.'); process.exit(1);
}
if (!args.includes('--local-development-only')) {
    console.error('Explicit local fixture opt-in required: --local-development-only'); process.exit(1);
}
const fixtures = Object.freeze([
    {Name:'Demo Lina Haddad', Major:'Software Engineering', Contact:'lina.trainee@example.com', Status:'Confirmed'},
    {Name:'Demo Omar Salem', Major:'Computer Science', Contact:'omar.trainee@example.com', Status:'Confirmed'},
    {Name:'Demo Sara Nasser', Major:'Computer Engineering', Contact:'sara.trainee@example.com', Status:'Confirmed'},
    {Name:'Demo Accepted Applicant', Major:'Software Engineering', Contact:'accepted@example.com', Status:'Accepted'}
]);
function escapeHtml(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
function selectRows(rows, input) {
    const query = String(input || '').trim();
    if (query.length > 100 || /[\x00-\x1f\x7f<>]/.test(query)) throw new Error('Use up to 100 plain-text characters for name or major.');
    return rows.filter(row => row.Status === 'Confirmed' && (row.Name.toLowerCase().includes(query.toLowerCase()) || row.Major.toLowerCase().includes(query.toLowerCase())));
}
function renderRows(template, rows) {
    return rows.map(row => template.replace(/<%#: Eval\("(Name|Major|Contact)"\) %>/g, (_, key) => escapeHtml(row[key]))).join('');
}
function attr(markup, name) { const match=markup.match(new RegExp('\\b'+name+'="([^"]*)"')); return match ? match[1] : ''; }
const page = fs.readFileSync(path.join(folder,'MyTrainees.aspx'),'utf8').replace(/^\uFEFF/,'');
const template = (page.match(/<ItemTemplate>([\s\S]*?)<\/ItemTemplate>/) || [])[1];
if (!template || !['Name','Major','Contact'].every(key => template.includes('Eval("'+key+'")'))) throw new Error('The actual trainee ItemTemplate has changed; review the preview renderer.');
function browserPreview(rows, template) {
    const input=document.getElementById('fixtureSearch'), list=document.getElementById('fixtureList');
    const results=document.getElementById('fixtureResults'), error=document.getElementById('fixtureError');
    const empty=document.getElementById('fixtureEmpty'), loading=document.querySelector('.trainees-loading');
    const section=document.querySelector('.trainees-page');
    document.getElementById('fixtureTotal').textContent=String(rows.filter(row => row.Status==='Confirmed').length);
    function render() {
        error.textContent=''; input.removeAttribute('aria-invalid');
        try {
            const matches=selectRows(rows,input.value);
            list.innerHTML=renderRows(template,matches);
            results.textContent=matches.length+' matching trainees — offline fixtures';
            empty.hidden=matches.length!==0;
        } catch (failure) {
            list.innerHTML=''; results.textContent=''; empty.hidden=true;
            error.textContent=failure.message; input.setAttribute('aria-invalid','true');
        }
    }
    document.getElementById('fixtureSearchForm').addEventListener('submit',event=>{
        event.preventDefault(); section.setAttribute('aria-busy','true'); loading.hidden=false;
        requestAnimationFrame(()=>{render();loading.hidden=true;section.removeAttribute('aria-busy');});
    });
    render();
}
function documentHtml() {
    let body=page.match(/<section\b[\s\S]*?<\/section>/)[0];
    body=body.replace(/<asp:Panel\b[^>]*Visible="false"[^>]*>[\s\S]*?<\/asp:Panel>/g,'');
    body=body.replace(/<asp:Panel\b[^>]*ID="UnavailableState"[^>]*>[\s\S]*?<\/asp:Panel>/g,'');
    body=body.replace(/<asp:Repeater\b[\s\S]*?<\/asp:Repeater>/g,'<ul id="fixtureList" class="trainees-list"></ul><div id="fixtureEmpty" class="trainees-empty" role="status" hidden><h3>No matching fixture trainees</h3><p>Try another name or major.</p></div>');
    body=body.replace(/<asp:Panel\b[^>]*ID="SearchPanel"[^>]*>([\s\S]*?)<\/asp:Panel>/g,'<form id="fixtureSearchForm" class="trainees-search">$1</form>');
    body=body.replace(/<asp:Label\b([^>]*?)\s*\/>/g,(_,a)=>{
        const id=attr(a,'ID'),cls=escapeHtml(attr(a,'CssClass'));
        if(id==='SearchLabel') return '<label for="fixtureSearch" class="'+cls+'">Search trainees by name or major</label>';
        const ids={TotalCount:'fixtureTotal',ResultCount:'fixtureResults',SearchError:'fixtureError'};
        const text=id==='CompanyName'?'Example Training Company (OFFLINE)':attr(a,'Text');
        return '<span'+(ids[id]?' id="'+ids[id]+'"':'')+' class="'+cls+'"'+(id==='SearchError'?' role="alert"':'')+'>'+escapeHtml(text)+'</span>';
    });
    body=body.replace(/<asp:TextBox\b[^>]*\/>/g,'<input id="fixtureSearch" type="text" class="form-control" maxlength="100" placeholder="Name or major" aria-describedby="fixtureError" autocomplete="off">');
    body=body.replace(/<asp:Button\b[^>]*\/>/g,'<button type="submit" class="btn btn-primary">Search</button>');
    if (/<asp:|<%/.test(body)) throw new Error('Unconverted server markup; preview stopped.');
    const styles=['Content/bootstrap.min.css','Shared/uims.css','Company/MyTrainees/MyTrainees.css'].map(p=>fs.readFileSync(path.join(app,p),'utf8').replace(/^\uFEFF/,'')).join('\n');
    const safeJson=value=>JSON.stringify(value).replace(/</g,'\\u003c');
    const script=escapeHtml.toString()+'\n'+selectRows.toString()+'\n'+renderRows.toString()+'\n('+browserPreview.toString()+')('+safeJson(fixtures)+','+safeJson(template)+');';
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>My Trainees — OFFLINE FIXTURES</title><style>'+styles+'\nbody{padding:24px;background:#f6f9f8}.fixture-notice{max-width:1200px;margin:0 auto 24px;padding:16px;border:2px dashed #8b6a20;border-radius:8px;background:#fff7db} @media(max-width:420px){body{padding:16px}}</style></head><body><aside class="fixture-notice"><strong>OFFLINE DEVELOPMENT PREVIEW — NOT LIVE FIREBASE DATA</strong><p class="mb-1">Dummy identity: supervisor.test@example.com · CompanySupervisor. No account, password, login session or Firebase connection exists in this preview.</p><p class="mb-0">Three fake confirmed trainees; one accepted-only applicant is excluded. Search and loading are browser simulations. Original ItemTemplate/CSS are reused; shared navigation and ASP.NET authorization are not reproduced.</p></aside>'+body+'<script>'+script+'</script></body></html>';
}
if(args.includes('--self-test')) {
    let checks=0;function check(value){assert.ok(value);checks++;}
    check(selectRows(fixtures,'').length===3);
    check(selectRows(fixtures,'LINA').length===1);
    check(selectRows(fixtures,' computer ').length===2);
    check(selectRows(fixtures,'Accepted Applicant').length===0);
    check(selectRows(fixtures,'no matching name').length===0);
    for(const invalid of ['<script>', 'x'.repeat(101), 'a\0b']){assert.throws(()=>selectRows(fixtures,invalid));checks++;}
    const encoded=renderRows(template,[{Name:'<script>alert(1)</script>',Major:'A&B',Contact:'"fixture"@example.com'}]);
    check(encoded.includes('&lt;script&gt;')&&!encoded.includes('<script>'));
    check(encoded.includes('A&amp;B')&&encoded.includes('&quot;fixture&quot;'));
    const html=documentHtml(); check(html.includes('OFFLINE DEVELOPMENT PREVIEW')); check(!html.includes('<asp:'));
    check(!/fetch\(|XMLHttpRequest|firebase\.initializeApp|Session\[|idToken/.test(html));
    console.log('PASS: '+checks+' offline preview checks; existing ItemTemplate rendering, search, accepted exclusion, validation, encoding and no network client. No server or Firebase account was started.');
    process.exit(0);
}
const assembly=path.join(app,'bin','UniversityInternshipManagmentSystem.dll');
const check=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-Command',"$ErrorActionPreference='Stop'; $a=[Reflection.Assembly]::Load([IO.File]::ReadAllBytes($env:UIMS_PREVIEW_ASSEMBLY)); $d=$a.GetCustomAttributes([Diagnostics.DebuggableAttribute],$false); if(-not ($d | Where-Object {$_.IsJITOptimizerDisabled})){exit 2}; 'DEBUG_OK'"],{encoding:'utf8',windowsHide:true,env:{...process.env,UIMS_PREVIEW_ASSEMBLY:assembly}});
if(check.status!==0 || !check.stdout.includes('DEBUG_OK')) {
    console.error('Refused: a Debug-built team application is required. This preview cannot start against a Release build. Build the existing solution in Debug, then run again. No account or Firebase data was changed.'); process.exit(1);
}
const index=args.indexOf('--port');
const port=index<0?60111:Number(args[index+1]);
if(!Number.isInteger(port)||port<1024||port>65535) throw new Error('Use a local port from 1024 to 65535.');
const html=documentHtml();
const server=http.createServer((req,res)=>{
    if(req.socket.remoteAddress!=='127.0.0.1' || req.headers.host!=='127.0.0.1:'+port || req.headers.origin || req.headers['sec-fetch-site']==='cross-site') {res.writeHead(403);res.end('Local preview only');return;}
    if(req.method!=='GET'||req.url!=='/'){res.writeHead(404);res.end();return;}
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'none'; img-src data:; font-src 'none'; form-action 'none'; frame-ancestors 'none'; base-uri 'none'"});res.end(html);
});
server.listen(port,'127.0.0.1',()=>console.log('OFFLINE ONLY: http://127.0.0.1:'+port+'/ — no login or Firebase requests. Ctrl+C stops the preview.'));
server.on('error',error=>{console.error('Local preview could not start: '+error.code);process.exitCode=1;});