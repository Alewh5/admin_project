(function () {
    const BACKEND_HTTP = 'http://localhost:3000';

    function getSocketUrl() {
        if (window.location.protocol === 'https:') {
            return BACKEND_HTTP.replace(/^http:/, 'https:');
        }
        return BACKEND_HTTP;
    }

    const state = {
        roomId: '',
        currentUser: '',
        agentName: '',
        currentState: 0,
        unreadCount: 0,
    };

    let socket = null;
    let reconnectAttempts = 0;
    const MAX_RECONNECT_ATTEMPTS = 10;
    const RECONNECT_BASE_DELAY_MS = 1500;
    let reconnectTimer = null;
    let isIntentionalDisconnect = false;

    const CSS = `
        #mp-widget-container{position:fixed;bottom:20px;right:20px;z-index:9999;font-family:sans-serif}
        #mp-bubble{width:60px;height:60px;background:#007bff;border-radius:50%;cursor:pointer;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 10px rgba(0,0,0,0.2);transition:transform 0.2s;position:relative;float:right}
        #mp-bubble:hover{transform:scale(1.05)}
        #mp-bubble svg{width:30px;height:30px;fill:white}
        #mp-badge{position:absolute;top:-5px;right:-5px;background:#ff3b30;color:white;border-radius:50%;padding:4px 8px;font-size:12px;font-weight:bold;display:none}
        #mp-chat-window{width:350px;height:500px;background:white;border-radius:12px;box-shadow:0 5px 25px rgba(0,0,0,0.2);display:none;flex-direction:column;overflow:hidden;margin-bottom:15px}
        #mp-chat-header{background:#007bff;color:white;padding:15px;font-weight:bold;display:flex;justify-content:space-between;align-items:center}
        #mp-chat-body{flex:1;padding:15px;overflow-y:auto;background:#f9f9f9;display:flex;flex-direction:column}
        #mp-chat-footer{padding:10px;background:white;border-top:1px solid #eee;display:none}
        .mp-input{width:100%;padding:10px;margin-bottom:10px;border:1px solid #ccc;border-radius:6px;box-sizing:border-box}
        .mp-btn{width:100%;padding:12px;background:#007bff;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:bold}
        .mp-btn:hover{background:#0056b3}
        .mp-msg{margin-bottom:10px;padding:10px 14px;border-radius:15px;max-width:80%;word-wrap:break-word}
        .mp-msg-visitor{background:#007bff;color:white;align-self:flex-end;border-bottom-right-radius:2px}
        .mp-msg-agent{background:#e5e5ea;color:black;align-self:flex-start;border-bottom-left-radius:2px}
        .mp-msg-system{background:transparent;color:#888;font-size:12px;text-align:center;align-self:center;max-width:100%;font-style:italic;padding:4px 0}
        .mp-msg-error{background:#fff0f0;color:#cc0000;border:1px solid #ffcccc;border-radius:8px;font-size:12px;padding:8px 12px;align-self:flex-end;max-width:90%}
        #mp-chat-input-row{display:flex;gap:8px;align-items:center}
        #mp-send-btn{background:#007bff;color:white;border:none;padding:10px 15px;border-radius:6px;cursor:pointer}
        #mp-file-label{cursor:pointer;background:#e5e5ea;padding:10px;border-radius:6px;display:flex;align-items:center;justify-content:center}
        #mp-file-label svg{width:20px;height:20px;fill:#333}
        .mp-center-box{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;text-align:center}
        .mp-chat-img{max-width:100%;border-radius:8px;margin-top:5px;cursor:pointer}
        #mp-connection-banner{background:#fff3cd;color:#856404;font-size:11px;text-align:center;padding:4px 8px;display:none;border-bottom:1px solid #ffc107}
        #mp-upload-spinner{display:none;font-size:12px;color:#555;text-align:right;padding:0 4px 6px;font-style:italic}
        .mp-stars { display: flex; justify-content: center; gap: 5px; margin: 15px 0; }
        .mp-star { font-size: 30px; color: #ccc; cursor: pointer; transition: color 0.2s; }
        .mp-star.active { color: #f5b301; }
        .mp-feedback { width: 100%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 6px; resize: none; height: 60px; box-sizing: border-box; font-family: sans-serif; }
    `;

    const HTML = `
        <div id="mp-chat-window">
            <div id="mp-chat-header">
                <span id="mp-header-title">Soporte en línea</span>
                <div>
                    <span id="mp-min-btn" style="cursor:pointer; font-size:24px; margin-right:15px; line-height:1;">&minus;</span>
                    <span id="mp-close-btn" style="cursor:pointer; font-size:24px; line-height:1;">&times;</span>
                </div>
            </div>
            <div id="mp-connection-banner">⚠ Reconectando con el servidor...</div>
            <div id="mp-chat-body"></div>
            <div id="mp-typing-indicator" style="display:none; padding: 0 15px 10px; font-size: 12px; color: #888; font-style: italic; background: #f9f9f9;">El agente está escribiendo...</div>
            <div id="mp-chat-footer">
                <div id="mp-upload-spinner">Subiendo archivo...</div>
                <div id="mp-chat-input-row">
                    <label id="mp-file-label" for="mp-file-input">
                        <svg viewBox="0 0 24 24"><path d="M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5a2.5 2.5 0 0 1 5 0v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5a2.5 2.5 0 0 0 5 0V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.04 2.46 5.5 5.5 5.5s5.5-2.46 5.5-5.5V6h-1.5z"/></svg>
                    </label>
                    <input type="file" id="mp-file-input" style="display:none;" accept="image/jpeg,image/png,image/gif,image/webp">
                    <input type="text" id="mp-msg-input" class="mp-input" placeholder="Escribe un mensaje..." style="margin-bottom:0;">
                    <button id="mp-send-btn">Enviar</button>
                </div>
            </div>
        </div>
        <div id="mp-bubble">
            <div id="mp-badge">0</div>
            <svg viewBox="0 0 24 24"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"></path></svg>
        </div>
    `;

    function initDOM() {
        const style = document.createElement('style');
        style.innerHTML = CSS;
        document.head.appendChild(style);

        const container = document.createElement('div');
        container.id = 'mp-widget-container';
        container.innerHTML = HTML;
        document.body.appendChild(container);
    }

    let bubble, badge, chatWindow, minBtn, closeBtn, chatBody,
        typingIndicator, chatFooter, sendBtn, msgInput, fileInput,
        headerTitle, connectionBanner, uploadSpinner;

    function bindDOMRefs() {
        bubble = document.getElementById('mp-bubble');
        badge = document.getElementById('mp-badge');
        chatWindow = document.getElementById('mp-chat-window');
        minBtn = document.getElementById('mp-min-btn');
        closeBtn = document.getElementById('mp-close-btn');
        chatBody = document.getElementById('mp-chat-body');
        typingIndicator = document.getElementById('mp-typing-indicator');
        chatFooter = document.getElementById('mp-chat-footer');
        sendBtn = document.getElementById('mp-send-btn');
        msgInput = document.getElementById('mp-msg-input');
        fileInput = document.getElementById('mp-file-input');
        headerTitle = document.getElementById('mp-header-title');
        connectionBanner = document.getElementById('mp-connection-banner');
        uploadSpinner = document.getElementById('mp-upload-spinner');
    }

    function saveSession() {
        localStorage.setItem('mp_chat_session', JSON.stringify({
            roomId: state.roomId,
            currentUser: state.currentUser,
            agentName: state.agentName,
            currentState: state.currentState,
            unreadCount: state.unreadCount,
        }));
    }

    function loadSession() {
        const saved = localStorage.getItem('mp_chat_session');
        if (!saved) return;
        const data = JSON.parse(saved);
        state.roomId = data.roomId || '';
        state.currentUser = data.currentUser || '';
        state.agentName = data.agentName || '';
        state.currentState = data.currentState || 0;
        state.unreadCount = data.unreadCount || 0;

        if (state.unreadCount > 0 && chatWindow.style.display === 'none') {
            badge.innerText = state.unreadCount;
            badge.style.display = 'block';
        }

        bubble.style.display = 'flex';
        chatWindow.style.display = 'none';
        renderState();

        if (state.roomId && state.currentState > 0 && state.currentState < 3) {
            connectSocket();
            fetchHistory();
        }
    }

    function clearSession() {
        localStorage.removeItem('mp_chat_session');
        state.roomId = '';
        state.currentUser = '';
        state.agentName = '';
        state.currentState = 0;
        state.unreadCount = 0;
    }

    function connectSocket() {
        if (socket && socket.connected) return;

        isIntentionalDisconnect = false;

        const socketUrl = getSocketUrl();
        socket = io(socketUrl, {
            transports: ['websocket'],
            reconnection: false,
        });

        socket.on('connect', onSocketConnect);
        socket.on('disconnect', onSocketDisconnect);
        socket.on('connect_error', onSocketError);
        socket.on('user_joined', onUserJoined);
        socket.on('receive_message', onReceiveMessage);
        socket.on('user_typing', onUserTyping);
        socket.on('room_closed', onRoomClosed);
    }

    function disconnectSocket() {
        isIntentionalDisconnect = true;
        clearTimeout(reconnectTimer);
        reconnectAttempts = 0;
        if (socket) {
            socket.disconnect();
            socket = null;
        }
    }

    function scheduleReconnect() {
        if (isIntentionalDisconnect) return;
        if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
            appendSystemMessage('No se pudo reconectar. Recarga la página.', '#cc0000');
            return;
        }
        const delay = Math.min(RECONNECT_BASE_DELAY_MS * Math.pow(2, reconnectAttempts), 30000);
        reconnectAttempts++;
        connectionBanner.style.display = 'block';
        reconnectTimer = setTimeout(() => {
            if (socket) socket.disconnect();
            socket = null;
            connectSocket();
        }, delay);
    }

    function onSocketConnect() {
        reconnectAttempts = 0;
        connectionBanner.style.display = 'none';
        socket.emit('join_room', {
            roomId: state.roomId,
            userId: state.currentUser,
            role: 'visitor',
        });
    }

    function onSocketDisconnect(reason) {
        if (isIntentionalDisconnect) return;
        if (reason === 'io server disconnect') {
            return;
        }
        scheduleReconnect();
    }

    function onSocketError() {
        scheduleReconnect();
    }

    function onUserJoined(data) {
        if (data.role !== 'agent') return;
        state.agentName = data.userId;
        state.currentState = 2;
        saveSession();
        renderState();
        fetchHistory();
        appendSystemMessage(`${state.agentName} se ha unido a la conversación.`);
    }

    function onReceiveMessage(data) {
        if (data.type === 'internal') return;

        if (state.currentState === 1 && data.role === 'agent') {
            state.agentName = data.senderId;
            state.currentState = 2;
            saveSession();
            renderState();
        }

        if (state.currentState !== 2) return;

        appendMessage(data);
        if (data.role === 'agent') typingIndicator.style.display = 'none';
        if (chatWindow.style.display === 'none' && data.senderId !== state.currentUser) {
            state.unreadCount++;
            badge.innerText = state.unreadCount;
            badge.style.display = 'block';
            saveSession();
        }
    }

    function onUserTyping(data) {
        if (data.role !== 'agent') return;
        typingIndicator.style.display = data.isTyping ? 'block' : 'none';
        if (data.isTyping) chatBody.scrollTop = chatBody.scrollHeight;
    }

    function onRoomClosed() {
        disconnectSocket();
        state.currentState = 3;
        saveSession();
        renderState();
    }

    function renderState() {
        if (state.currentState === 0) {
            chatBody.innerHTML = '';
            chatFooter.style.display = 'none';
            typingIndicator.style.display = 'none';
            headerTitle.innerText = 'Soporte en línea';
            chatBody.innerHTML = `
                <h4 style="margin-top:0; color:#333;">Inicia una conversación</h4>
                <input type="text" id="mp-fname" class="mp-input" placeholder="Nombre">
                <input type="text" id="mp-lname" class="mp-input" placeholder="Apellido">
                <input type="email" id="mp-email" class="mp-input" placeholder="Correo electrónico">
                <input type="text" id="mp-reason" class="mp-input" placeholder="Motivo de la consulta">
                <button id="mp-start-btn" class="mp-btn">Empezar</button>
            `;
            document.getElementById('mp-start-btn').addEventListener('click', startChat);

        } else if (state.currentState === 1) {
            chatFooter.style.display = 'none';
            typingIndicator.style.display = 'none';
            headerTitle.innerText = 'Soporte en línea';
            chatBody.innerHTML = `
                <div class="mp-center-box">
                    <h3 style="color:#333; margin-bottom:10px;">Conversación iniciada</h3>
                    <p style="color:#666; font-size:14px;">Estás en cola. En unos momentos te atenderá un agente.</p>
                </div>
            `;
        } else if (state.currentState === 2) {
            chatFooter.style.display = 'block';
            headerTitle.innerText = `Conectado con: ${state.agentName || 'Agente'}`;
        } else if (state.currentState === 3) {
            chatFooter.style.display = 'none';
            typingIndicator.style.display = 'none';
            headerTitle.innerText = 'Calificar Servicio';
            chatBody.innerHTML = `
                <div class="mp-center-box" style="padding: 20px;">
                    <h3 style="color:#333; margin-bottom:10px; text-align:center;">Conversación Finalizada</h3>
                    <p style="color:#666; font-size:14px; margin-bottom:15px; text-align:center;">¿Cómo calificas nuestro servicio?</p>
                    <div class="mp-stars" id="mp-star-container">
                        <span class="mp-star" data-val="1">★</span>
                        <span class="mp-star" data-val="2">★</span>
                        <span class="mp-star" data-val="3">★</span>
                        <span class="mp-star" data-val="4">★</span>
                        <span class="mp-star" data-val="5">★</span>
                    </div>
                    <textarea id="mp-feedback-text" class="mp-feedback" placeholder="Déjanos tus comentarios (opcional)"></textarea>
                    <button id="mp-submit-rating" class="mp-btn">Enviar Calificación</button>
                    <button id="mp-skip-rating" style="background:transparent; border:none; color:#888; margin-top:10px; cursor:pointer; text-decoration:underline;">Omitir</button>
                </div>
            `;
            bindRatingEvents();
        }
    }

    function bindRatingEvents() {
        let ratingValue = 0;
        const stars = document.querySelectorAll('.mp-star');
        stars.forEach(star => {
            star.addEventListener('click', (e) => {
                ratingValue = parseInt(e.target.getAttribute('data-val'));
                stars.forEach(s => {
                    if (parseInt(s.getAttribute('data-val')) <= ratingValue) {
                        s.classList.add('active');
                    } else {
                        s.classList.remove('active');
                    }
                });
            });
        });

        document.getElementById('mp-submit-rating').addEventListener('click', async () => {
            if (ratingValue === 0) {
                alert('Por favor selecciona una calificación antes de enviar.');
                return;
            }
            const feedback = document.getElementById('mp-feedback-text').value.trim();
            const btn = document.getElementById('mp-submit-rating');
            btn.innerText = 'Enviando...';
            btn.disabled = true;

            try {
                await fetch(`${BACKEND_HTTP}/api/chat/room/${state.roomId}/rate`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ rating: ratingValue, feedback: feedback })
                });
            } catch (e) { }

            finishAndClose();
        });

        document.getElementById('mp-skip-rating').addEventListener('click', finishAndClose);
    }

    function finishAndClose() {
        clearSession();
        chatWindow.style.display = 'none';
        bubble.style.display = 'flex';
        renderState();
    }

    function appendMessage(data) {
        if (data.type === 'internal') return;
        const msgDiv = document.createElement('div');
        msgDiv.classList.add('mp-msg');
        msgDiv.classList.add(data.senderId === state.currentUser ? 'mp-msg-visitor' : 'mp-msg-agent');

        if (data.type === 'image' && data.fileUrl) {
            const link = document.createElement('a');
            link.href = data.fileUrl;
            link.target = '_blank';
            link.style.display = 'block';
            const img = document.createElement('img');
            img.src = data.fileUrl;
            img.classList.add('mp-chat-img');
            link.appendChild(img);
            msgDiv.appendChild(link);
            if (data.message) {
                const txt = document.createElement('div');
                txt.innerText = data.message;
                txt.style.marginTop = '5px';
                msgDiv.appendChild(txt);
            }
        } else {
            msgDiv.innerText = data.message;
        }

        chatBody.appendChild(msgDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
    }

    function appendSystemMessage(text, color) {
        const div = document.createElement('div');
        div.classList.add('mp-msg-system');
        if (color) div.style.color = color;
        div.innerText = text;
        chatBody.appendChild(div);
        chatBody.scrollTop = chatBody.scrollHeight;
    }

    function appendErrorMessage(text) {
        const div = document.createElement('div');
        div.classList.add('mp-msg', 'mp-msg-error');
        div.innerText = '⚠ ' + text;
        chatBody.appendChild(div);
        chatBody.scrollTop = chatBody.scrollHeight;
    }

    async function fetchHistory() {
        try {
            const res = await fetch(`${BACKEND_HTTP}/api/chat/history/${state.roomId}`);
            if (res.status === 200) {
                const history = await res.json();
                chatBody.innerHTML = '';

                let hasAgentMessage = false;
                let lastAgentName = '';

                history.forEach(msg => {
                    appendMessage(msg);
                    if (msg.role === 'agent' && msg.type !== 'internal') {
                        hasAgentMessage = true;
                        lastAgentName = msg.senderId;
                    }
                });

                if (state.currentState === 1 && hasAgentMessage) {
                    state.agentName = lastAgentName;
                    state.currentState = 2;
                    saveSession();
                    renderState();
                }
            }
        } catch (e) {
        }
    }

    async function startChat() {
        const fname = document.getElementById('mp-fname').value.trim();
        const lname = document.getElementById('mp-lname').value.trim();
        const email = document.getElementById('mp-email').value.trim();
        const reason = document.getElementById('mp-reason').value.trim();

        if (!fname || !email || !reason) {
            ['mp-fname', 'mp-email', 'mp-reason'].forEach(id => {
                const el = document.getElementById(id);
                if (el && !el.value.trim()) el.style.borderColor = '#dc3545';
            });
            return;
        }

        state.currentUser = email;
        const generatedId = 'room_' + Date.now();

        try {
            const response = await fetch(`${BACKEND_HTTP}/api/chat/room`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    roomId: generatedId,
                    firstName: fname,
                    lastName: lname,
                    email: email,
                    reason: reason,
                    originUrl: window.location.href,
                }),
            });

            if (response.status === 201) {
                const data = await response.json();
                state.roomId = data.roomId;
                state.currentState = 1;
                saveSession();
                renderState();
                connectSocket();
            } else {
                appendErrorMessage('No se pudo iniciar la conversación. Intenta de nuevo.');
            }
        } catch (e) {
            appendErrorMessage('Error de conexión. Verifica tu red e intenta de nuevo.');
        }
    }

    function sendMessage() {
        const text = msgInput.value.trim();
        if (!text || !socket || !socket.connected) {
            if (!socket || !socket.connected) {
                appendErrorMessage('Sin conexión. Espera que se reconecte y vuelve a intentar.');
            }
            return;
        }
        socket.emit('send_message', {
            roomId: state.roomId,
            message: text,
            senderId: state.currentUser,
            role: 'visitor',
            type: 'text',
        });
        socket.emit('typing', { roomId: state.roomId, isTyping: false, role: 'visitor' });
        msgInput.value = '';
        msgInput.focus();
    }

    const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

    async function handleFileUpload(file) {
        if (!file) return;

        if (!ALLOWED_TYPES.includes(file.type)) {
            appendErrorMessage('Tipo de archivo no permitido. Solo se aceptan imágenes (JPG, PNG, GIF, WEBP).');
            fileInput.value = '';
            return;
        }
        if (file.size > MAX_FILE_SIZE_BYTES) {
            appendErrorMessage(`El archivo es demasiado grande (máx. 5 MB). El tuyo pesa ${(file.size / 1024 / 1024).toFixed(1)} MB.`);
            fileInput.value = '';
            return;
        }

        uploadSpinner.style.display = 'block';

        const formData = new FormData();
        formData.append('file', file);

        try {
            const response = await fetch(`${BACKEND_HTTP}/api/chat/upload`, {
                method: 'POST',
                body: formData,
            });

            if (response.ok) {
                const data = await response.json();
                if (socket && socket.connected) {
                    socket.emit('send_message', {
                        roomId: state.roomId,
                        message: '',
                        senderId: state.currentUser,
                        role: 'visitor',
                        type: 'image',
                        fileUrl: data.fileUrl,
                    });
                } else {
                    appendErrorMessage('Archivo subido, pero no hay conexión activa. Reconectando...');
                }
            } else {
                const errData = await response.json().catch(() => ({}));
                const serverMsg = errData.message || `Error del servidor (${response.status}).`;
                appendErrorMessage(serverMsg);
            }
        } catch (e) {
            appendErrorMessage('No se pudo subir el archivo. Verifica tu conexión e intenta de nuevo.');
        } finally {
            uploadSpinner.style.display = 'none';
            fileInput.value = '';
            msgInput.focus();
        }
    }

    function bindEvents() {
        bubble.addEventListener('click', () => {
            chatWindow.style.display = 'flex';
            bubble.style.display = 'none';
            state.unreadCount = 0;
            badge.style.display = 'none';
            badge.innerText = '0';
            saveSession();
            if (state.currentState === 0) renderState();
        });

        minBtn.addEventListener('click', () => {
            chatWindow.style.display = 'none';
            bubble.style.display = 'flex';
        });

        closeBtn.addEventListener('click', () => {
            if (state.currentState === 2) {
                if (confirm('¿Estás seguro que deseas finalizar y cerrar la conversación?')) {
                    if (socket) socket.emit('close_room', { roomId: state.roomId });
                    disconnectSocket();
                    state.currentState = 3;
                    saveSession();
                    renderState();
                }
            } else if (state.currentState === 1) {
                if (confirm('¿Estás seguro que deseas cancelar la solicitud?')) {
                    if (socket) socket.emit('close_room', { roomId: state.roomId });
                    disconnectSocket();
                    finishAndClose();
                }
            } else if (state.currentState === 3) {
                finishAndClose();
            } else {
                chatWindow.style.display = 'none';
                bubble.style.display = 'flex';
            }
        });

        sendBtn.addEventListener('click', sendMessage);

        msgInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') sendMessage();
        });

        let typingTimeout;
        msgInput.addEventListener('input', () => {
            if (!socket || !socket.connected) return;
            socket.emit('typing', {
                roomId: state.roomId,
                isTyping: msgInput.value.length > 0,
                role: 'visitor',
                previewText: msgInput.value,
            });
            clearTimeout(typingTimeout);
            typingTimeout = setTimeout(() => {
                if (!socket || !socket.connected) return;
                socket.emit('typing', { roomId: state.roomId, isTyping: false, role: 'visitor', previewText: '' });
            }, 2000);
        });

        fileInput.addEventListener('change', (e) => {
            handleFileUpload(e.target.files[0]);
        });
    }

    function loadSocketIo(callback) {
        if (window.io) { callback(); return; }
        const script = document.createElement('script');
        script.src = 'https://cdn.socket.io/4.7.2/socket.io.min.js';
        script.onload = callback;
        script.onerror = () => { };
        document.head.appendChild(script);
    }

    function init() {
        initDOM();
        bindDOMRefs();
        bindEvents();
        loadSocketIo(() => {
            setTimeout(loadSession, 100);
        });
    }

    init();

})();