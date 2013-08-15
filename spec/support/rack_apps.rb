def setup_rack_application(application, options = {}, mixpanel_options = {})
  stub!(:app).and_return(Mixpanel::Middleware.new(application.new(options), MIX_PANEL_TOKEN, mixpanel_options))
end

def html_document
  <<-EOT
    <html>
      <head>
      </head>
      <body>
      </body>
    </html>
  EOT
end

class DummyApp
  def initialize(options)
    @response_with = {}
    @response_with[:status] = options[:status] || "200"
    @response_with[:headers] = options[:headers] || {}
    @response_with[:body] = wrap(options[:body] || '')
  end

  def call(env)
    [@response_with[:status], @response_with[:headers], @response_with[:body]]
  end

  private
  def wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end

def large_script
  <<-EOT
    <script type='text/javascript'>
      //<![CDATA[
        function update_milestone_divs(obj){
          $('#milestones').show();
          $('#milestones').children('div').hide();

          divid = obj.options[obj.selectedIndex].value;

          divid = '#milestone_' + divid
          $(divid).show()
        }

        $(document).ready(function() {
          /*
          * First step is to create title attributes for the rows in the table
          * This isn't needed if the required 'title' attribute is already set in the HTML in the
          * DOM
          */
          $('#milestone_table tbody tr').each( function() {
            var sTitle;
            var nTds = $('td', this);
            var sPic = $(nTds[3]).text();
            var sName = $(nTds[1]).text();

            sTitle =  '<img src='+sPic+' height=60 width=60/><br>'+sName;
            this.setAttribute( 'title', sTitle );

          } );

          /* Apply the tooltips */
          $('#milestone_table tbody tr[title]').tooltip( {
            "delay": 0,
            "track": true,
            "fade": 250
          } );

          /* Init DataTables */
          $('#milestone_table').dataTable({
            "iDisplayLength": 10,
            "aaSorting": [[ 2, "desc" ]],
          });
        });
      //]]>
    </script>
    <style type='text/css'>
      /*<![CDATA[*/
        #milestone_table {
          width:550px;

        }

        td { vertical-align:middle;}
        td.select { width: 50px; padding-left:10px;}
        td.title { text-align:left; font-size:120%; }
        td.picture { width: 60px; display:none;}
        td.when {  text-align: center; width: 100px; }
      /*]]>*/
    </style>
    <div class='item_box' id='milestone_attachment'>
      <form action="http://big.application.com/inbox_items/28" enctype="multipart/form-data" method="post"><div style="margin:0;padding:0;display:inline"><input name="_method" type="hidden" value="put" /><input name="authenticity_token" type="hidden" value="QF1y2YhiuVJv7qS3u5jShr6mvqjx0NWAD1FPPJTwY/w=" /></div>
        <input id="transform_to" name="transform_to" type="hidden" value="milestone_attachment" />
        <div>
          <div class='addBox roundo' style='float:left; display:block; margin:5px 0; padding:0 5px 5px 5px;'>
            <p>
              Attach to memory for
              <select name='person_id' onchange='update_milestone_divs(this)'>
                <option></option>
                <option value='40'>  Bill</option>
                <option disabled='disabled'>  Sally (no memories)</option>
                <option value='169'>  Tim</option>
                <option disabled='disabled'>  Betty (no memories)</option>
                <option value='173'>  Ted</option>
              </select>
            </p>
          </div>
        </div>
        <div id='milestones'>
          <div id='milestone_40' style='display:none;'>
            <h4>Memories for Bill</h4>
            <table id='milestone_table'>
              <thead>
                <tr>
                  <th>Select</th>
                  <th>Title</th>
                  <th>When?</th>
                  <th style='display:none;'>Picture</th>
                </tr>
              </thead>
              <tr>
                <td class='select'><input id="milestone_40_179" name="milestone_40" type="radio" value="179" /></td>
                <td class='title'>Ran a race</td>
                <td class='when'>10/07/2010</td>
                <td class='picture'>
                  /system/photos/first_and_milestones/179/thumb/ed0e4428.jpeg
                </td>
              </tr>
            </table>
          </div>
          <div id='milestone_169' style='display:none;'>
            <h4>Memories for Tim</h4>
            <table id='milestone_table'>
              <thead>
                <tr>
                  <th>Select</th>
                  <th>Title</th>
                  <th>When?</th>
                  <th style='display:none;'>Picture</th>
                </tr>
              </thead>
              <tr>
                <td class='select'><input id="milestone_169_204" name="milestone_169" type="radio" value="204" /></td>
                <td class='title'>Kicked ball first time</td>
                <td class='when'>03/12/1978</td>
                <td class='picture'>
                </td>
              </tr>
            </table>
          </div>
          <div id='milestone_173' style='display:none;'>
            <h4>Memories for Ted</h4>
            <table id='milestone_table'>
              <thead>
                <tr>
                  <th>Select</th>
                  <th>Title</th>
                  <th>When?</th>
                  <th style='display:none;'>Picture</th>
                </tr>
              </thead>
              <tr>
                <td class='select'><input id="milestone_173_195" name="milestone_173" type="radio" value="195" /></td>
                <td class='title'>Testing the log</td>
                <td class='when'>11/03/2010</td>
                <td class='picture'>
                </td>
              </tr>
              <tr>
                <td class='select'><input id="milestone_173_196" name="milestone_173" type="radio" value="196" /></td>
                <td class='title'>another test</td>
                <td class='when'>11/03/2010</td>
                <td class='picture'>
                </td>
              </tr>
              <tr>
                <td class='select'><input id="milestone_173_197" name="milestone_173" type="radio" value="197" /></td>
                <td class='title'>one more</td>
                <td class='when'>11/01/2010</td>
                <td class='picture'>
                </td>
              </tr>
              <tr>
                <td class='select'><input id="milestone_173_198" name="milestone_173" type="radio" value="198" /></td>
                <td class='title'>great time</td>
                <td class='when'>11/03/2010</td>
                <td class='picture'>
                </td>
              </tr>
              <tr>
                <td class='select'><input id="milestone_173_199" name="milestone_173" type="radio" value="199" /></td>
                <td class='title'>please</td>
                <td class='when'>11/03/2010</td>
                <td class='picture'>
                </td>
              </tr>
            </table>
          </div>
          <div class='clear'></div>
        </div>
        <div class="clear"></div><div id="buttonArea" style="width: 550px; margin-left: -20px"><input class="btn topper botter lbump20 blue " disabled="disabled" name="commit" style="display:none;" type="submit" value=".. saving .." /><input class="btn topper botter lbump20 blue " id="submit_btn" name="commit" onclick="$(this).hide(); $(this).prev().show();" type="submit" value="Save" /><a href="/inbox_items" class="btnSm topper botter lbump20">Cancel</a><a href="/inbox_items/28" class="btnSm red topper botter lbump20" id="delete_btn" onclick="if (confirm('Are you sure you want to delete this?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);var s = document.createElement('input'); s.setAttribute('type', 'hidden'); s.setAttribute('name', 'authenticity_token'); s.setAttribute('value', 'QF1y2YhiuVJv7qS3u5jShr6mvqjx0NWAD1FPPJTwY/w='); f.appendChild(s);f.submit(); };return false;">Delete</a></div><div class="clear"></div>
      </form>
    </div>
  EOT
end
