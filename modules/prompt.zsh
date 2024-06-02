#!/usr/bin/env zsh

alien_prompt_colorize() {
  local __content="$1"
  local __fg="$2"
  local __bg="$3"
  [[ -n "$__fg" ]] && echo -en "%F{$__fg}"
  [[ -n "$__bg" ]] && echo -en "%K{$__bg}"
  echo -en "${__content}"
  [[ -n "$__bg" ]] && echo -en "%k"
  [[ -n "$__fg" ]] && echo -en "%f"
}

alien_prompt_section_short_path() {
  local path="$PWD"
  local home="$HOME"
  
  # Replace home directory path with ~
  if [[ "$path" == "$home"* ]]; then
    path="~${path#$home}"
  fi

  local segments=("${(@s:/:)path}")
  local num_segments=${#segments[@]}
  local display_segments=3  # Number of end segments to display

  local shortened_path=""
  if (( num_segments > display_segments + 1 )); then
    for (( i = num_segments - display_segments; i < num_segments; i++ )); do
      shortened_path+="/${segments[i]}"
    done
    shortened_path="..${shortened_path}"
  else
    shortened_path="$path"
  fi
  
  # Ensure the current folder is always displayed
  if [[ "$shortened_path" == "~" ]]; then
    shortened_path="~/${segments[-1]}"
  fi

  __section=(
    content " ${shortened_path} "
    foreground $ALIEN_SECTION_PATH_FG
    background $ALIEN_SECTION_PATH_BG
    separator 1
  )
}


alien_prompt_render_right() {
  [[ ${#ALIEN_SECTIONS_RIGHT} -ne 0 ]] || return
  local __render_mode=$1
  local __separator=$ALIEN_SECTIONS_RIGHT_SEP_SYM
  local __last_bg=
  local __newline_in_left=
  local __rprompt_prefix=
  local __rprompt_suffix=
  # using ZLE_RPROMPT_INDENT=0 causes a bug, therefore we emulate it in this way
  echo -ne "%1{ %}"
  # if there is a newline in PROMPT we have to move the cursor to get RPROMPT on the first line
  if [[ ${ALIEN_SECTIONS_LEFT[(r)newline]} == newline ]]; then
    __rprompt_prefix='%{'$'\e[1A''%}' # one line up
    __rprompt_suffix='%{'$'\e[1B''%}' # one line down
  fi
  echo -ne $__rprompt_prefix
  for section in $ALIEN_SECTIONS_RIGHT; do
    # section can define a render-mode in which it will be rendered
    # render-mode is defined by appending :<mode>
    IFS=":" read -r __section_name __section_render_mode <<< $section
    local __section_function="alien_prompt_section_${__section_name}"
    # check if a function is defined for the section
    if whence -w "$__section_function" >/dev/null && \
      { [[ -z "$__section_render_mode" ]] || [[ "$__section_render_mode" == "$__render_mode" ]] ;}
    then
      # declare variable in which the section-function writes its information
      typeset -A __section=()
      $__section_function
      # skip section if section-function returned false
      [[ $? -ne 0 ]] && continue
      local __content=${__section[content]}
      local __fg=${__section[foreground]}
      local __bg=${__section[background]}
      local __sep=${__section[separator]+${__section[separator]}}
      [[ -n $__sep ]] && alien_prompt_colorize "$__separator" "$__bg" $__last_bg
      __last_bg="$__bg"
      alien_prompt_colorize "$__content" "$__fg" "$__bg"
    fi
  done
  echo -ne $__rprompt_suffix
}

