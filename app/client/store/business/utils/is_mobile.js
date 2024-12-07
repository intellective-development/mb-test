const user_agent = window && window.navigator && window.navigator.userAgent;

const isIOS = () => /iPhone|iPad|iPod/i.test(user_agent);
const isAndroid = () => /Android/i.test(user_agent);
const isMobile = () => /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(user_agent);

export default isMobile;
export { isIOS, isAndroid, isMobile };
